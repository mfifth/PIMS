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

          excluded_products = []

          if item["modifiers"]
            item["modifiers"].each do |mod|
              mod_name = mod["name"]
              next unless mod_name.present?

              if negation_modifier?(mod_name)
                product = find_product_for_modifier(account, mod_name)
                if product
                  excluded_products << (product.id || product.sku)
                  Rails.logger.info("Skipping deduction for '#{product.name}' due to negation modifier '#{mod_name}'")
                end
                next
              end

              process_modifier(account, mod, quantity_sold, location)
            end
          end

          RecipeOrderProcessorService.new(location).process_recipe(recipe, quantity_sold, excluded_modifiers: excluded_products.compact)
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

    modifier_quantity = (modifier["quantity"] || 1).to_i
    total_quantity = modifier_quantity * parent_quantity

    update_inventory_item(product, location, -total_quantity)
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
    inventory_item.quantity = [inventory_item.quantity, 0].max # prevent negative quantity
    inventory_item.save!
  end
end
