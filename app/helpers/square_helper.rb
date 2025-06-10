module SquareHelper
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
              mod_id = mod["catalog_object_id"]
              mod_quantity = mod["quantity"].to_i
              next if mod_id.blank? || mod_quantity <= 0
              
              process_product_order(account, mod_id, mod_quantity * quantity_sold, location)
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

  def process_product_order(account, item_id, quantity, location)
    product = account.products.find_by(sku: item_id)
    inventory_item = location.inventory_items.find_by(product: product)
    return unless product && inventory_item

    inventory_item.quantity -= quantity
    inventory_item.save!
    
    Rails.logger.info("Deducted #{quantity} #{product.unit_type} of #{product.name}")
  end
end
