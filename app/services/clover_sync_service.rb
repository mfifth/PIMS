class CloverSyncService
	def initialize(account)
		@account = account
	end

	def sync_all
		items = fetch_all_items

		items.each do |item|
			item["stockCounts"]&.each do |stock|
				location_data = stock["location"]
				next unless location_data
	
				location = account.locations.find_or_create_by!(name: location_data["name"])
				inventory_item = location.inventory_items.find_or_initialize_by(product: product)
				inventory_item.quantity = stock["quantity"].to_i
				inventory_item.save!
	
				product = account.products.find_or_initialize_by(
					sku: item["id"], 
					name: item['name']
				)
	
				product.price = item["price"].to_i
				product.save!
			end
		end
	end

	def fetch_all_items
		all_items = []
		cursor = nil

		loop do
			url = "https://api.clover.com/v3/merchants/#{@account.clover_merchant_id}/items?expand=stockCounts&limit=100"
			url += "&cursor=#{cursor}" if cursor

			response = Faraday.get(url) do |req|
				req.headers["Authorization"] = "Bearer #{@account.clover_access_token}"
			end
			data = JSON.parse(response.body)

			all_items += data["elements"]
			cursor = data["cursor"]
			break unless cursor
		end

		all_items
	end
end
