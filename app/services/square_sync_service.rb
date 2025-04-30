class SquareSyncService
  attr_reader :account, :client

  def initialize(account)
    @account = account
    @client = Square::Client.new(
      access_token: account.square_access_token,
      environment: Rails.env.production? ? 'production' : 'sandbox'
    )
  end

  def sync_all
    sync_locations
    sync_menu_items_and_categories
    sync_inventory_for_all_locations

    Notification.find_or_create_by(message: I18n.t('notifications.sync_complete'), notification_type: "notice")
  rescue Square::ApiError => e
    log_error("Square API error during sync_all", e)
  rescue => e
    log_error("Failed to sync Square data", e)
  end

  def sync_locations
    response = handle_rate_limited_request { client.locations.list_locations }
    return unless response.success?

    response.data.locations.each do |sq_loc|
      location = account.locations.find_or_initialize_by(location_uid: sq_loc.id)
      location.name = sq_loc.name
      location.save!
    end
  rescue => e
    log_error("Failed syncing locations", e)
  end

  def sync_menu_items_and_categories
    objects = []
    cursor = nil

    loop do
      response = handle_rate_limited_request do
        client.catalog.list_catalog(cursor: cursor, types: 'ITEM,CATEGORY')
      end
      break unless response.success?

      objects += response.data.objects
      cursor = response.data.cursor
      break unless cursor
    end

    categories = objects.select { |o| o.type == 'CATEGORY' }.index_by(&:id)

    ActiveRecord::Base.transaction do
      objects.each do |obj|
        next unless obj.type == 'ITEM'

        if meal_item?(obj, categories)
          sync_recipe(obj, categories)
        else
          sync_product_metadata(obj)
        end
      end
    end
  rescue => e
    log_error("Failed to sync menu items and categories", e)
  end

  def sync_inventory_for_all_locations
    account.locations.each do |location|
      sync_location_inventory(location)
    end
  rescue => e
    log_error("Failed syncing inventory for all locations", e)
  end

  private

  def sync_location_inventory(location)
    cursor = nil

    loop do
      response = handle_rate_limited_request do
        client.inventory.list_inventory_counts(
          location_ids: [location.location_uid],
          catalog_object_types: 'ITEM',
          cursor: cursor
        )
      end
      break unless response.success?

      ActiveRecord::Base.transaction do
        response.data.counts.each do |count|
          product = account.products.find_or_initialize_by(sku: count.catalog_object_id)
          product.name ||= count.catalog_object_name
          product.save!

          InventoryItem.find_or_initialize_by(product: product, location: location).tap do |item|
            item.quantity = count.quantity.to_f
            item.save!
          end
        end
      end

      cursor = response.data.cursor
      break unless cursor
    end
  rescue => e
    log_error("Failed syncing inventory for location #{location.id}", e)
  end

  def meal_item?(item, categories)
    return false unless item.item_data

    if item.item_data.custom_attribute_values
      meal_attr = item.item_data.custom_attribute_values["is_meal"]
      return meal_attr&.boolean_value if meal_attr
    end

    category_name = categories[item.item_data.category_id]&.category_data&.name
    MealClassifier.new(item, category_name).meal?
  end

  def sync_recipe(item, categories)
    recipe = account.recipes.find_or_initialize_by(uid: item.id)
    recipe.name = item.item_data.name
    recipe.save!
  end

  def sync_product_metadata(item)
    product = account.products.find_or_initialize_by(sku: item.id)
    product.name = item.item_data.name
    product.description = item.item_data.description
    product.save!
  end

  def handle_rate_limited_request(max_retries = 5)
    retries = 0

    begin
      response = yield
      if response.status_code == 429
        wait_time = response.headers['retry-after']&.to_i || 2**retries
        sleep(wait_time)
        raise "Rate limited"
      end
      return response
    rescue => e
      retries += 1
      if retries <= max_retries
        sleep(2**retries)
        retry
      else
        raise e
      end
    end
  end

  def log_error(context, error)
    Rails.logger.error("[SquareSyncService] #{context}: #{error.message}\n#{error.backtrace.join("\n")}")
    Notification.create(
      message: "#{context}: #{error.message}",
      notification_type: "error"
    )
  end
end
