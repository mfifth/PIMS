class CloverOrderSyncJob < ApplicationJob
  queue_as :default

  def perform(account_id, order_id)
    account = Account.includes(:products, :recipes, locations: :inventory_items).find(account_id)
    order = fetch_order(account, order_id)

    line_items = order["lineItems"] || []
    location_id = order.dig('device', 'location', 'id')
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
          RecipeOrderProcessorService.new(location).process_recipe(recipe, quantity)
        else
          process_product_order(account, item_id, quantity, location)
        end
      end
    end
  rescue => e
    Rails.logger.error("Failed to process Clover order #{order_id}: #{e.message}")
    raise e # Re-raise to retry the job if configured
  end

  private

  def process_product_order(account, item_id, quantity, location)
    product = account.products.find_by(sku: item_id)
    return unless product

    inventory_item = location.inventory_items.find_or_initialize_by(product: product)
    inventory_item.quantity -= quantity
    inventory_item.save!
    
    Rails.logger.info("Deducted #{quantity} #{product.unit_type} of #{product.name}")
  end

  def fetch_order(account, order_id)
    url = "https://api.clover.com/v3/merchants/#{account.clover_merchant_id}/orders/#{order_id}?expand=lineItems&expand=device"

    response = Faraday.get(url) do |req|
      req.headers["Authorization"] = "Bearer #{account.clover_access_token}"
    end

    raise "Failed to fetch Clover order" unless response.success?

    JSON.parse(response.body)
  end
end
