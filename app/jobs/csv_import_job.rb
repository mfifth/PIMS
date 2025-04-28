class CsvImportJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |exception|
    notify_user("Failed, Data malformed: #{exception.message}", :alert)
    cleanup_files
  end

  def perform(file_path, user_id, location_id)
    @file_path = file_path
    @user = User.find_by(id: user_id)
    @location = Location.find_by(id: location_id)
    @failed_products = []

    process_csv(file_path)
    
    if @failed_products.any?
      notify_user("CSV import completed with errors. Some products failed to import.", :alert)
      @failed_products.each do |failed_product|
        notify_user("Failed to import product: #{failed_product[:name]} - Errors: #{failed_product[:errors]}", :alert)
      end
    else
      notify_user("CSV import completed successfully!", :notice)
    end
  ensure
    cleanup_files
  end

  private

  def process_csv(file_path)
    CSV.foreach(file_path, headers: true) do |row|
      begin
        ActiveRecord::Base.transaction do
          import_row(row.to_h)
        end
      rescue ActiveRecord::RecordInvalid => e
        @failed_products << { name: row['name'], errors: e.record.errors.full_messages.join(", ") }
      rescue StandardError => e
        Rails.logger.error "Unexpected error with row #{row['sku']}: #{e.message}"
        @failed_products << { name: row['name'], errors: "Unexpected error: #{e.message}" }
      end
    end
  end

  def import_row(row_data)
    product = find_or_initialize_product(row_data)
    inventory_item = @location.inventory_items.find_or_initialize_by(product: product)
    
    inventory_item.assign_attributes(
      quantity: row_data['quantity'].presence || inventory_item.quantity,
      low_threshold: row_data['low_threshold'].presence || inventory_item.low_threshold
    )
    
    if row_data['batch_number'].present? && row_data['expiration_date'].present?
      product.batch_id = handle_batch(product, row_data)
    end

    product.save!
    inventory_item.save!
  end

  def find_or_initialize_product(row)
    product = Product.find_or_initialize_by(
      sku: row['sku'],
      account: @user.account
    )

    product.assign_attributes(
      name: row['name'],
      price: row['price'],
      unit_type: row['unit_type'] || 'units',
      perishable: ActiveModel::Type::Boolean.new.cast(row['perishable'])
    )

    if row['category'].present?
      product.category = @user.account.categories.find_or_create_by(name: row['category'])
    end
    
    product
  end

  def handle_batch(product, row)
    batch = Batch.find_or_initialize_by(
      account_id: product.account.id,
      batch_number: row['batch_number']
    )

    batch.manufactured_date = row['manufactured_date']
    batch.expiration_date = row['expiration_date']
    batch.notification_days_before_expiration = row['notification_days_before_expiration'] || 0
    batch.save!
    batch.id
  end

  def notify_user(message, type = :notice)
    return unless @user.account
    
    Notification.create!(
      account: @user.account,
      message: message,
      notification_type: type
    )
  rescue => e
    Rails.logger.error "Failed to create notification: #{e.message}"
  end

  def cleanup_files
    File.delete(@file_path) if @file_path && File.exist?(@file_path)
  rescue => e
    Rails.logger.error "Failed to cleanup CSV file: #{e.message}"
  end
end
