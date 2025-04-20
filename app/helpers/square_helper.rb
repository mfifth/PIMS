module SquareHelper
  private

	def process_order(account, data)
		order_id = data["id"]
		order_items = data["line_items"]
	
		order_items.each do |item|
			product_sku = item["catalog_object_id"]
			quantity_sold = item["quantity"].to_i
	
			product = account.products.find_by(sku: product_sku)
			next unless product
	
			location = account.locations.find_by(square_location_id: data["location_id"])
	
			next unless location
	
			inventory_item = InventoryItem.find_or_initialize_by(product: product, location: location)
			inventory_item.quantity -= quantity_sold
	
			inventory_item.save!
			Rails.logger.info("Updated inventory for Product: #{product.sku}, Location: #{location.name}, Quantity: #{inventory_item.quantity}")
		end
	
		Rails.logger.info("Processed order #{order_id} for account #{account.id}")
	end
end