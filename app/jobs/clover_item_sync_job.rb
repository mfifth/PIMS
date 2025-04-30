# app/jobs/clover_item_sync_job.rb
class CloverItemSyncJob < ApplicationJob
  queue_as :default

  def perform(account_id, item_id)
    account = Account.find(account_id)
    response = Faraday.get("https://api.clover.com/v3/merchants/#{account.clover_merchant_id}/items/#{item_id}?expand=stockCounts,categories") do |req|
      req.headers["Authorization"] = "Bearer #{account.clover_access_token}"
    end

    unless response.success?
      raise "Clover API error: #{response.status} - #{response.body}"
    end

    item = JSON.parse(response.body)

    if meal_item?(item)
      sync_recipe(account, item)
    else
      product = sync_product(account, item)

      if item["stockCounts"]
        item["stockCounts"].each do |stock|
          next unless stock["location"]
          sync_inventory_item(account, product, stock)
        end
      end
    end
  end

  private

  def sync_product(account, item)
    product = account.products.find_or_initialize_by(sku: item["id"])
    product.name = item["name"]
    product.price = item["price"].to_i
    product.save!
    product
  end

  def sync_inventory_item(account, product, stock)
    location_data = stock["location"]
    location = account.locations.find_or_create_by!(location_uid: location_data["id"]) do |loc|
			loc.name = location_data["name"]
		end

    inventory_item = location.inventory_items.find_or_initialize_by(product: product)
    inventory_item.quantity = stock["quantity"].to_i
    inventory_item.save!
  end

  def sync_recipe(account, item)
    recipe = account.recipes.find_or_initialize_by(uid: item["id"])
    recipe.name = item["name"]
    recipe.save!
  end

  def meal_item?(item)
    name = item["name"].to_s
    description = item["description"].to_s
    category_name = item.dig("categories", 0, "name").to_s

    MealClassifier.new(
      OpenStruct.new(item_data: OpenStruct.new(name: name, description: description)),
      category_name
    ).meal?
  end
end
