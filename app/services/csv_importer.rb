class CsvImporter
  def initialize(user:, location:, file_contents:)
    @user = user
    @location = location
    @file_contents = file_contents
    @account = user.account
    @failed_products = []
    @batch_cache = {}
  end

  def import
    preload_caches
    process_csv
    notify_results
  end

  private

  def preload_caches
    skus = CSV.parse(@file_contents, headers: true).map { |row| row['sku'] }
    @product_cache = Product.where(sku: skus, account: @account).index_by(&:sku)
    @category_cache = @account.categories.index_by(&:name)
  end

  def process_csv
    CSV.parse(@file_contents, headers: true) do |row|
      begin
        ActiveRecord::Base.transaction do
          import_row(row.to_h)
        end
      rescue ActiveRecord::RecordInvalid => e
        @failed_products << { name: row['name'], errors: e.record.errors.full_messages.join(", ") }
      rescue StandardError => e
        Rails.logger.error "Unexpected error with row #{row['sku']}: #{e.message}"
        @failed_products << { name: row['name'], errors: I18n.t("csv_import.errors.unexpected", message: e.message) }
      end
    end
  end

  def import_row(row_data)
    product = find_or_initialize_product(row_data)
    inventory_item = @location.inventory_items.find_or_initialize_by(product: product)

    inventory_item.assign_attributes(
      quantity: row_data['quantity'].presence || inventory_item.quantity,
      low_threshold: row_data['low_stock_alert'].presence || inventory_item.low_threshold,
      unit_type: row_data['unit_type'].presence || 'units'
    )

    if row_data['batch_number'].present? && row_data['expiration_date'].present?
      product.batch_id = find_or_create_batch(row_data['batch_number'], row_data).id
    end

    product.save!
    inventory_item.save!
  end

  def find_or_initialize_product(row)
    product = @product_cache[row['sku']] || Product.new(sku: row['sku'], account: @account)

    product.assign_attributes(
      name: row['name'],
      price: row['price'],
      perishable: ActiveModel::Type::Boolean.new.cast(row['perishable'])
    )

    if row['category'].present?
      product.category = @category_cache[row['category']] || @account.categories.create!(name: row['category'])
      @category_cache[row['category']] = product.category
    end

    product
  end

  def find_or_create_batch(batch_number, row)
    @batch_cache[batch_number] ||= Batch.find_or_create_by!(account: @account, batch_number: batch_number) do |batch|
      batch.manufactured_date = row['manufactured_date']
      batch.expiration_date = row['expiration_date']
      batch.notification_days_before_expiration = row['notification_days_before_expiration'] || 0
    end
  end

  def notify_results
    if @failed_products.any?
      notify(I18n.t("csv_import.completed_with_errors"), :alert)

      @failed_products.each do |failed_product|
        notify(
          I18n.t("csv_import.failed_product", name: failed_product[:name], errors: failed_product[:errors]),
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
