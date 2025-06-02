class CsvImporter
  require 'csv'

  def initialize(user:, location:, file_contents:)
    @user          = user
    @location      = location
    @file_contents = file_contents
    @account       = user.account
    @failed_rows   = []
  end

  def import
    preload_caches
    process_csv
    notify_results
  end

  private

  def cleaned_csv_text
    @cleaned_csv_text ||= begin
      text = @file_contents.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      text.sub("\uFEFF", '')
    end
  end

  def preload_caches
    skus = []
    CSV.parse(cleaned_csv_text, headers: true) do |row|
      skus << row['sku'] if row['sku'].present?
    end
    @product_cache  = Product.where(sku: skus, account: @account).index_by(&:sku)
    @category_cache = @account.categories.index_by(&:name)
  end

  def process_csv
    CSV.parse(cleaned_csv_text, headers: true) do |row|
      row_data = normalize_keys(row.to_h)
      begin
        import_row(row_data)
      rescue => e
        @failed_rows << {
          name: row_data['name'] || 'Unknown',
          sku: row_data['sku'],
          errors: full_error_details(e),
          row: row_data,
          backtrace: e.backtrace.join("\n")
        }
        Rails.logger.error "CSV import error on SKU=#{row_data['sku']}: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end
  end

  def import_row(row)
    unless row['sku'].present? && row['name'].present?
      raise "Missing required fields: SKU and Name are required"
    end

    product = find_or_initialize_product(row)
    product.price = row['price'].to_f if row['price'].present?
    
    unless product.save
      raise "Product validation failed: #{product.errors.full_messages.join(', ')}"
    end

    inventory = @location.inventory_items.find_or_initialize_by(product: product)
    inventory.assign_attributes(
      quantity: row['quantity'].to_f,
      low_threshold: row['low_stock_alert'].to_f,
      unit_type: row['unit_type'].presence || 'units'
    )

    if row['batch_number'].present? && row['expiration_date'].present?
      inventory.batch = find_or_create_batch(row['batch_number'], row)
    end

    inventory.save!
  rescue ActiveRecord::RecordInvalid => e
    raise "Validation failed: #{e.record.errors.full_messages.join(', ')}"
  rescue => e
    raise "Import failed: #{e.message}"
  end

  def find_or_initialize_product(data)
    product = @product_cache[data['sku']] || Product.new(sku: data['sku'], account: @account)

    product.name       = data['name']
    product.perishable = cast_boolean(data['perishable'])

    if data['category'].present?
      category = @category_cache[data['category']] ||=
                 @account.categories.create!(name: data['category'])
      product.category = category
    end

    product
  end

  def cast_boolean(val)
    return false if val.nil?
    normalized = val.to_s.strip.downcase
    %w[true 1 yes y t].include?(normalized)
  end

  def find_or_create_batch(batch_number, data)
    Batch.find_or_create_by!(account: @account, batch_number: batch_number) do |batch|
      batch.manufactured_date                 = data['manufactured_date']
      batch.expiration_date                   = data['expiration_date']
      batch.notification_days_before_expiration = data['notification_days_before_expiration'].to_i
    end
  end

  def notify_results
    total = CSV.parse(cleaned_csv_text, headers: true).count
    success = total - @failed_rows.size

    if @failed_rows.any?
      notify(I18n.t('csv_import.completed_with_errors', success_count: success, error_count: @failed_rows.size), :alert)
      @failed_rows.each do |f|
        notify(I18n.t('csv_import.failed_row', name: f[:name], sku: f[:sku], errors: f[:errors]), :alert)
      end
    else
      notify(I18n.t('csv_import.success'), :notice)
    end
  end

  def notify(message, type = :notice)
    Notification.create!(account: @account, message: message, notification_type: type)
  rescue => e
    Rails.logger.error "Notification error: #{e.message}"
  end

  def normalize_keys(hash)
    hash.transform_keys { |k| k.to_s.strip.downcase }
  end
end
