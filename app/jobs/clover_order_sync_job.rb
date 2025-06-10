class CloverOrderSyncJob < ApplicationJob
  MODIFIER_KEYWORDS = %w[extra add double triple xtra x addon].freeze
  NEGATION_KEYWORDS = %w[no without hold omit exclude].freeze
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
          if line["modifications"]
            line["modifications"].each do |mod|
              process_clover_modifier(account, mod, quantity, location)
            end
          end
          
          RecipeOrderProcessorService.new(location).process_recipe(recipe, quantity)
        else
          process_product_order(account, item_id, quantity, location)
        end
      end
    end
  rescue => e
    Rails.logger.error("Failed to process Clover order #{order_id}: #{e.message}")
    raise e
  end

  private

  def process_clover_modifier(account, modifier, parent_quantity, location)
    mod_name = modifier.dig("modification", "name")
    return unless mod_name.present?
    return if negation_modifier?(mod_name)

    product = find_product_for_modifier(account, mod_name)
    return unless product

    process_product_order(account, product.sku, modifier["quantity"].to_i * parent_quantity, location)
  end

  def negation_modifier?(modifier_name)
    cleaned = modifier_name.downcase.gsub(/[^a-z\s]/, '')
    NEGATION_KEYWORDS.any? { |word| cleaned.match?(/\b#{word}\b/) }
  end

  def find_product_for_modifier(account, modifier_name)
    cleaned_name = clean_modifier_name(modifier_name)
    Product.find_product_by_fuzzy_name(account, modifier_name)
  end

  def clean_modifier_name(name)
    name.downcase
        .gsub(/\b(#{MODIFIER_KEYWORDS.join('|')})\b/i, '')
        .gsub(/[^a-z0-9\s]/, '')
        .strip
        .squeeze(' ')
  end

  def process_product_order(account, item_id, quantity, location)
    product = account.products.find_by(sku: item_id)
    inventory_item = location.inventory_items.find_by(product: product)
    return unless product && inventory_item

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
