module SquareHelper
  MODIFIER_KEYWORDS = %w[extra add double triple xtra x addon].freeze
  NEGATION_KEYWORDS = %w[no without hold omit exclude].freeze

  private

  def process_order(account, data)
    order_id = data["id"]
    order_items = data["line_items"]
    
    ActiveRecord::Base.transaction do
      order_items.each do |item|
        catalog_object_id = item["catalog_object_id"]
        quantity_sold = item["quantity"].to_i

        recipe = account.recipes.find_by(uid: catalog_object_id)
        
        if recipe
          location = account.locations.find_by(location_uid: data["location_id"])
          next unless location

          if item["modifiers"]
            item["modifiers"].each do |mod|
              process_modifier(account, mod, quantity_sold, location)
            end
          end

          RecipeOrderProcessorService.new(location).process_recipe(recipe, quantity_sold)
        else
          product = account.products.find_by(sku: catalog_object_id)
          next unless product

          location = account.locations.find_by(location_uid: data["location_id"])
          next unless location

          update_inventory_item(product, location, -quantity_sold)
        end
      end
    end

    Rails.logger.info("Processed order #{order_id} for account #{account.id}")
  end

  def process_modifier(account, modifier, parent_quantity, location)
    mod_name = modifier["name"]
    return unless mod_name.present?
    return if negation_modifier?(mod_name)

    product = find_product_for_modifier(account, mod_name)
    return unless product

    update_inventory_item(product, location, -parent_quantity)
  end

  def negation_modifier?(modifier_name)
    cleaned = modifier_name.downcase.gsub(/[^a-z\s]/, '')
    NEGATION_KEYWORDS.any? { |word| cleaned.match?(/\b#{word}\b/) }
  end

  def find_product_for_modifier(account, modifier_name)
    cleaned_name = clean_modifier_name(modifier_name)
    Product.find_product_for_modifier(account, modifier_name)
  end

  def clean_modifier_name(name)
    name.downcase
        .gsub(/\b(#{MODIFIER_KEYWORDS.join('|')})\b/i, '')
        .gsub(/[^a-z0-9\s]/, '')
        .strip
        .squeeze(' ')
  end

  def update_inventory_item(product, location, quantity_change)
    inventory_item = InventoryItem.find_by(product: product, location: location)
    return unless inventory_item

    inventory_item.quantity += quantity_change
    inventory_item.save!
  end
end