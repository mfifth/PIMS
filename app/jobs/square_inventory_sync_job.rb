class SquareInventorySyncJob < ApplicationJob
	queue_as :default

	def perform(account_id, data)
		account = Account.find_by(id: account_id)
		return unless account

		counts = data.dig("object", "inventory_counts")
		return unless counts.is_a?(Array)

		counts.each do |count|
			sku         = count["catalog_object_id"]
			location_id = count["location_id"]
			quantity    = count["quantity"].to_i

			product  = account.products.find_by(sku: sku)
			location = account.locations.find_by(square_location_id: location_id)
			next unless product && location

			inventory_item = InventoryItem.find_or_initialize_by(product: product, location: location)
			inventory_item.quantity = quantity
			inventory_item.save!
		end
	rescue => e
		Rails.logger.error("Square::InventoryUpdateJob failed: #{e.message}")
	end
end
