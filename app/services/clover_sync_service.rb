class CloverSyncService
  MAX_RETRIES = 5

  def initialize(account)
    @account = account
  end

  def sync_all
    fetch_all_items.each do |item|
      if meal_item?(item)
        sync_recipe(item)
      else
        product = sync_product(item)

        if item["stockCounts"]
          item["stockCounts"].each do |stock|
            next unless stock["location"]
            sync_inventory_item(product, stock)
          end
        end
      end
    end

    unless Notification.exists?(notification_type: "notice", message: I18n.t('notifications.sync_complete'))
      Notification.create(message: I18n.t('notifications.sync_complete'), notification_type: "notice")
    end
  rescue => e
    log_error("Clover sync_all failed", e)
  end

  private

  attr_reader :account

  def fetch_all_items
    all_items = []
    cursor = nil

    loop do
      url = "https://api.clover.com/v3/merchants/#{account.clover_merchant_id}/items?expand=stockCounts,categories&limit=100"
      url += "&cursor=#{cursor}" if cursor

      response = with_rate_limit_retries do
        Faraday.get(url) do |req|
          req.headers["Authorization"] = "Bearer #{account.clover_access_token}"
        end
      end

      unless response.success?
        raise "Clover API error: #{response.status} - #{response.body}"
      end

      data = JSON.parse(response.body)
      all_items += data["elements"]
      cursor = data["cursor"]
      break unless cursor
    end

    all_items
  end

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

  def sync_recipe(item)
    recipe = account.recipes.find_or_initialize_by(uid: item["id"])
    recipe.name = item["name"]
    recipe.price = item["price"].to_i
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

  def with_rate_limit_retries
    retries = 0

    begin
      response = yield
      if response.status == 429
        wait_time = response.headers["Retry-After"]&.to_i || (2**retries)
        sleep(wait_time)
        raise "Rate limited"
      end
      response
    rescue => e
      retries += 1
      if retries <= MAX_RETRIES
        sleep(2**retries)
        retry
      else
        raise e
      end
    end
  end

  def log_error(context, error)
    Rails.logger.error("[CloverSyncService] #{context}: #{error.message}\n#{error.backtrace.join("\n")}")
    Notification.create(
      message: "#{context}: #{error.message}",
      notification_type: "error"
    )
  end
end
