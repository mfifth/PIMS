class CsvImporter
  def initialize(user:, location:, file_contents:)
    @user = user
    @location = location
    @file_contents = file_contents
    @account = user.account
    @failed_rows = []
  end

  def import
    preload_caches
    process_csv
    notify_results
  end

  private

  def preload_caches
    skus = CSV.parse(@file_contents, headers: true).map { |row| row['sku'] }.compact
    @product_cache = Product.where(sku: skus, account: @account).index_by(&:sku)
    @category_cache = @account.categories.index_by(&:name)
  end

  def process_csv
    CSV.parse(@file_contents, headers: true) do |row|
      begin
        import_row(row.to_h)
      rescue => e
        @failed_rows << {
          name: row['name'] || 'Unknown',
          sku: row['sku'],
          errors: e.message,
          row: row.to_h
        }
        Rails.logger.error "Error processing row #{row.to_h}: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end
  end

  def import_row(row_data)
    unless row_data['sku'].present? && row_data['name'].present?
      raise "Missing required fields: SKU and Name are required"
    end

    product = find_or_initialize_product(row_data)
    inventory_item = @location.inventory_items.find_or_initialize_by(product: product)

    inventory_item.assign_attributes(
      quantity: row_data['quantity'].to_f,
      low_threshold: row_data['low_stock_alert'].to_f,
      unit_type: row_data['unit_type'] || 'units'
    )

    if row_data['batch_number'].present? && row_data['expiration_date'].present?
      inventory_item.batch = find_or_create_batch(row_data['batch_number'], row_data)
    end

    product.save!
    inventory_item.save!
  end

  def find_or_initialize_product(row)
    product = @product_cache[row['sku']] || Product.new(sku: row['sku'], account: @account)

    product.assign_attributes(
      name: row['name'],
      price: row['price'].to_f,
      perishable: cast_boolean(row['perishable'])
    )

    if row['category'].present?
      product.category = @category_cache[row['category']] || @account.categories.create!(name: row['category'])
      @category_cache[row['category']] = product.category
    end

    product
  end

  def cast_boolean(value)
    return false if value.nil?
  
    normalized = value.to_s.strip.downcase
    %w[true 1 yes y t].include?(normalized)
  end  

  def find_or_create_batch(batch_number, row)
    Batch.find_or_create_by!(account: @account, batch_number: batch_number) do |batch|
      batch.manufactured_date = row['manufactured_date']
      batch.expiration_date = row['expiration_date']
      batch.notification_days_before_expiration = row['notification_days_before_expiration'].to_i || 0
    end
  end

  def notify_results
    if @failed_rows.any?
      notify_summary = I18n.t("csv_import.completed_with_errors", 
        success_count: CSV.parse(@file_contents, headers: true).count - @failed_rows.count,
        error_count: @failed_rows.count
      )
      notify(notify_summary, :alert)

      @failed_rows.each do |failed_row|
        notify(
          I18n.t("csv_import.failed_row", 
            name: failed_row[:name],
            sku: failed_row[:sku],
            errors: failed_row[:errors]
          ),
          :alert
        )
      end
    else
      notify(I18n.t("csv_import.success"), :notice)
    end
  end

  def notify(message, type = :notice)
    Notification.create!(
      account: @account,
      message: message,
      notification_type: type
    )
  rescue => e
    Rails.logger.error "Failed to create notification: #{e.message}"
  end
end