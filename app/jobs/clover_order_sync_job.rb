class CloverOrderSyncJob < ApplicationJob
  queue_as :default

  def perform(account_id, order_id)
    account = Account.includes(:products, locations: :inventory_items).find(account_id)
    order = fetch_order(account, order_id)

    line_items = order["lineItems"] || []
    location_name = order.dig("device", "location", "name")
    return if location_name.blank?

    location = account.locations.find_by(name: location_name)
    return unless location

    line_items.each do |line|
      item_id  = line.dig("item", "id")
      quantity = line["quantity"].to_i
      next if item_id.blank? || quantity <= 0
      
      product = account.products.find_by(sku: item_id)
      next unless product

      inventory_item = location.inventory_items.find_by(product: product)
      inventory_item.quantity = inventory_item.quantity - quantity
      inventory_item.save
    end
  end

  private

  def fetch_order(account, order_id)
    url = "https://api.clover.com/v3/merchants/#{account.clover_merchant_id}/orders/#{order_id}?expand=lineItems&expand=device"

    response = Faraday.get(url) do |req|
      req.headers["Authorization"] = "Bearer #{account.clover_access_token}"
    end

    raise "Failed to fetch Clover order" unless response.success?

    JSON.parse(response.body)
  end
end
