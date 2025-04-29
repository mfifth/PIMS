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
    sync_locations_and_inventory
    sync_menu_items_and_products
    
    unless Notification.exists?(notification_type: "notice", message: I18n.t('notifications.sync_complete'))
      Notification.create(message: I18n.t('notifications.sync_complete'), notification_type: "notice")
    end
  rescue Square::ApiError => e
    log_error("Square API error during sync_all", e)
  rescue => e
    log_error("Failed to sync Square data", e)
  end

  def sync_locations_and_inventory
    response = client.locations.list_locations
    return unless response.success?

    response.data.locations.each do |sq_loc|
      location = account.locations.find_or_initialize_by(location_uid: sq_loc.id)
      location.name = sq_loc.name
      location.save!

      sync_location_inventory(location)
    end
  rescue Square::ApiError => e
    log_error("Square API error during location sync", e)
  end

  def sync_menu_items_and_products
    response = client.catalog.list_catalog(types: 'ITEM,CATEGORY')
    return unless response.success?

    objects = response.data.objects
    categories = objects.select { |o| o.type == 'CATEGORY' }.index_by(&:id)

    ActiveRecord::Base.transaction do
      objects.each do |obj|
        next unless obj.type == 'ITEM'

        if meal_item?(obj, categories)
          sync_recipe(obj, categories)
        else
          sync_product(obj)
        end
      end
    end
  rescue Square::ApiError => e
    log_error("Square API error during menu sync", e)
  rescue => e
    log_error("Failed to sync Square menu items and products", e)
  end

  private

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

  def sync_product(item)
    product = account.products.find_or_initialize_by(sku: item.id)
    product.name = item.item_data.name
    product.description = item.item_data.description
    product.save!
  end

  def sync_location_inventory(location)
    response = client.inventory.list_inventory_counts(
      location_ids: [location.location_uid],
      catalog_object_types: 'ITEM'
    )
    return unless response.success?

    ActiveRecord::Base.transaction do
      response.data.counts.each do |count|
        sync_product_and_inventory(location, count)
      end
    end
  rescue Square::ApiError => e
    log_error("Square API error during inventory sync", e)
  rescue => e
    log_error("Failed syncing Square inventory for #{location.id}", e)
  end

  def sync_product_and_inventory(location, count)
    product = account.products.find_or_initialize_by(sku: count.catalog_object_id)
    product.name = count.catalog_object_name if product.name.blank?
    product.save!

    InventoryItem.find_or_initialize_by(product: product, location: location).tap do |item|
      item.quantity = count.quantity.to_f
      item.save!
    end
  end

  def log_error(context, error)
    Rails.logger.error("[SquareSyncService] #{context}: #{error.message}\n#{error.backtrace.join("\n")}")
  end
end
