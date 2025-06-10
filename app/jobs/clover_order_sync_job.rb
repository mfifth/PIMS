class CloverOrderSyncJob < ApplicationJob
  queue_as :default

  def perform(account_id, order_id)
    account = Account.includes(:products, :recipes, locations: :inventory_items).find(account_id)
    order = fetch_order(account, order_id)
    return if order.blank?

    line_items = order["lineItems"] || []
    location_id = order.dig("device", "location", "id")
    return if location_id.blank?

    location = account.locations.find_by(location_uid: location_id)
    return unless location

    ActiveRecord::Base.transaction do
      line_items.each do |line|
        item_id  = line.dig("item", "id")
        quantity = line["quantity"].to_i
        next if item_id.blank? || quantity <= 0

        recipe = account.recipes.find_by(uid: item_id)

        if recipe
          process_recipe_line(account, recipe, line, quantity, location)
        else
          process_product_order(account, item_id, quantity, location)
        end
      end
    end
  rescue => e
    Rails.logger.error("Failed to process Clover order #{order_id}: #{e.message}")
    raise e
  end

  private

  def process_recipe_line(account, recipe, line, quantity, location)
    excluded_products = []

    if line["modifications"]
      line["modifications"].each do |mod|
        mod_name = mod.dig("modification", "name")
        next unless mod_name.present?

        if negation_modifier?(mod_name)
          product = find_product_for_modifier(account, mod_name)
          if product
            excluded_products << (product.id || product.sku)
            Rails.logger.info("Skipping deduction for '#{product.name}' due to negation modifier '#{mod_name}'")
          end
          next
        end

        process_clover_modifier(account, mod, quantity, location)
      end
    end

    RecipeOrderProcessorService.new(location).process_recipe(recipe, quantity, excluded_modifiers: excluded_products.compact)
    Rails.logger.info("Processed recipe '#{recipe.name}' x#{quantity} at location '#{location.name}'")
  end

  def process_clover_modifier(account, modifier, parent_quantity, location)
    mod_name = modifier.dig("modification", "name")
    return unless mod_name.present?
    return if negation_modifier?(mod_name)

    product = find_product_for_modifier(account, mod_name)
    return unless product

    modifier_quantity = (modifier["quantity"] || 1).to_i
    total_quantity = modifier_quantity * parent_quantity

    process_product_order(account, product.sku, total_quantity, location)
  end

  def negation_modifier?(modifier_name)
    cleaned = modifier_name.downcase.gsub(/[^a-z\s]/, '')
    NEGATION_KEYWORDS.any? { |word| cleaned.match?(/\b#{word}\b/) }
  end

  def find_product_for_modifier(account, modifier_name)
    cleaned_name = clean_modifier_name(modifier_name)

    product = account.products.find_by("LOWER(name) = ?", cleaned_name.downcase)

    unless product
      product = account.products.order(:name).find_by("LOWER(name) LIKE ?", "%#{cleaned_name.downcase}%")
      Rails.logger.warn("Using fuzzy match for modifier '#{modifier_name}' → matched product '#{product&.name}'") if product
    end

    product
  end

  def clean_modifier_name(name)
    name.downcase
        .gsub(/\b(#{MODIFIER_KEYWORDS.join('|')})\b/i, '')
        .gsub(/[^a-z0-9\s]/, '')
        .strip
        .squeeze(' ')
  end

  def process_product_order(account, item_id, quantity, location)
    product = account.products.find_by(sku: item_id)
    unless product
      Rails.logger.warn("Product with SKU #{item_id} not found for account #{account.id}")
      return
    end

    inventory_item = location.inventory_items.find_by(product: product)
    unless inventory_item
      Rails.logger.warn("Inventory item for product '#{product.name}' not found in location '#{location.name}'")
      return
    end

    new_quantity = inventory_item.quantity - quantity
    if new_quantity < 0
      Rails.logger.warn("Inventory for '#{product.name}' would go negative. Setting to 0 instead.")
      inventory_item.quantity = 0
    else
      inventory_item.quantity = new_quantity
    end

    inventory_item.save!
    Rails.logger.info("Deducted #{quantity} #{product.unit_type} of '#{product.name}' at location '#{location.name}' (remaining: #{inventory_item.quantity})")
  end

  def fetch_order(account, order_id)
    url = "https://api.clover.com/v3/merchants/#{account.clover_merchant_id}/orders/#{order_id}?expand=lineItems&expand=device"

    response = Faraday.get(url) do |req|
      req.headers["Authorization"] = "Bearer #{account.clover_access_token}"
    end

    if response.status == 404
      Rails.logger.warn("Clover order #{order_id} not found (404)")
      return nil
    end

    raise "Failed to fetch Clover order #{order_id}: #{response.status}" unless response.success?

    JSON.parse(response.body)
  end
end
