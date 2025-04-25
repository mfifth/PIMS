module SquareHelper
  private
  
  def process_order(account, data)
    order_id = data["id"]
    order_items = data["line_items"]

    order_items.each do |item|
      catalog_object_id = item["catalog_object_id"]
      quantity_sold = item["quantity"].to_i

      recipe = account.recipes.find_by(uid: catalog_object_id)
      
      if recipe
        location = account.locations.find_by(location_uid: data["location_id"])
        next unless location

        RecipeOrderProcessor.new(location).process_recipe(recipe, quantity_sold)
      else
        product = account.products.find_by(sku: catalog_object_id)
        next unless product

        location = account.locations.find_by(location_uid: data["location_id"])
        next unless location

        update_inventory_item(product, location, -quantity_sold)
      end
    end

    Rails.logger.info("Processed order #{order_id} for account #{account.id}")
  end

  def update_inventory_item(product, location, quantity_change)
    inventory_item = InventoryItem.find_by(product: product, location: location)
    inventory_item.quantity += quantity_change
    inventory_item.save!
  end
end
