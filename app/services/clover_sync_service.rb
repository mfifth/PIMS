class CloverSyncService
  def initialize(account)
    @account = account
  end

  def sync_all
    fetch_all_items.each do |item|
      next unless item["stockCounts"]

      product = sync_product(item)

      item["stockCounts"].each do |stock|
        next unless stock["location"]

        sync_inventory_item(product, stock)
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

  private

  attr_reader :account

  def sync_product(item)
    product = account.products.find_or_initialize_by(sku: item["id"])
    product.name = item["name"]
    product.price = item["price"].to_i
    product.save!
    product
  end

  def sync_inventory_item(product, stock)
    location_data = stock["location"]
    location = account.locations.find_or_create_by!(
      name: location_data["name"],
      location_uid: location_data["id"]
    )

    inventory_item = location.inventory_items.find_or_initialize_by(product: product)
    inventory_item.quantity = stock["quantity"].to_i
    inventory_item.save!
  end
end
