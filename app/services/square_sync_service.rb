class SquareSyncService
  def initialize(account)
    @account = account
    @client = Square::Client.new(
      access_token: account.square_access_token,
      environment: Rails.env.production? ? 'production' : 'sandbox'
    )
  end

  def sync_all
		response = @client.locations.list_locations
		return unless response.success?
	
		response.data.locations.each do |sq_loc|
			location = @account.locations.find_or_initialize_by(location_uid: sq_loc.id)
			location.name = sq_loc.name
			location.save!
	
			sync_location_inventory(location)
		end
	rescue => e
		Rails.logger.error("Failed to sync Square locations and inventory: #{e.message}")
	end	

  private

  def sync_location_inventory(location)
    response = @client.inventory.list_inventory_counts(
      location_ids: [location.location_uid],
      catalog_object_types: 'ITEM'
    )

    return unless response.success?

    ActiveRecord::Base.transaction do
      response.data.counts.each do |count|
        sku      = count.catalog_object_id
        name     = count.catalog_object_name
        quantity = count.quantity.to_i

        product = @account.products.find_or_initialize_by(sku: sku)
        product.name = name if product.name.blank?
        product.save!

        InventoryItem.find_or_initialize_by(product: product, location: location).tap do |item|
          item.quantity = quantity
          item.save!
        end
      end
    end
  rescue => e
    Rails.logger.error("Failed syncing Square inventory for #{location.id}: #{e.message}")
  end
end
