class SquareSyncService
  attr_reader :account, :client

  def initialize(account)
    @account = account
    @client = Square::Client.new(
      access_token: account.square_access_token,
      environment: Rails.env.production? ? 'production' : 'sandbox'
    )
  end

  def sync_all
    sync_locations
    sync_menu_items
  rescue => e
    Rails.logger.error("Failed to sync Square data: #{e.message}")
  end

  def sync_locations
    response = client.locations.list_locations
    return unless response.success?

    response.data.locations.each do |sq_loc|
      location = account.locations.find_or_initialize_by(location_uid: sq_loc.id)
      location.name = sq_loc.name
      location.save!
    end
  rescue => e
    Rails.logger.error("Failed to sync Square locations: #{e.message}")
  end

  def sync_menu_items
    response = client.catalog.list_catalog(types: 'ITEM')
    return unless response.success?

    ActiveRecord::Base.transaction do
      response.data.objects.each do |item|
        next unless item.type == 'ITEM'

        recipe = account.recipes.find_or_initialize_by(uid: item.id)
        recipe.name = item.item_data.name
        recipe.save!
      end
    end
  rescue => e
    Rails.logger.error("Failed to sync Square menu items: #{e.message}")
  end
end
