class SquareController < ApplicationController
  skip_before_action :verify_authenticity_token

  def start
    redirect_to oauth_authorize_url
  end

  def callback
    if params[:error]
      redirect_to root_path, alert: "Authorization failed: #{params[:error_description] || params[:error] || 'Unknown error'}"
      return
    end

    result = exchange_code_for_token(params[:code])
    if result.success?
      access_token = result.data.access_token
      refresh_token = result.data.refresh_token
      merchant_id = result.data.merchant_id

      Current.account.update(
        square_access_token: access_token,
        square_refresh_token: refresh_token,
        square_merchant_id: merchant_id
      )

      redirect_to dashboard_path, notice: t('notifications.square_account_connected')
    else
      redirect_to root_path, alert: t('notifications.oauth_failed')
    end
  end

  def sync_locations
    client = create_square_client(Current.account.square_access_token)

    if token_expired?(Current.account.square_access_token)
      refresh_square_token
      client = create_square_client(Current.account.square_access_token)
    end

    response = client.locations.list_locations
    if response.success?
      response.data.locations.each do |sq_loc|
        location = Current.account.locations.find_or_initialize_by(name: sq_loc.name)
        location.square_location_id = sq_loc.id unless location.square_location_id
        location.save!
      end
      redirect_to square_locations_path, notice: t('notifications.square_synced', quantity: response.data.locations.size)
    else
      redirect_back fallback_location: root_path, alert: t('notifications.failed_fetch')
    end
  end

  def sync_products
    client = create_square_client(Current.account.square_access_token)
  
    if token_expired?(Current.account.square_access_token)
      refresh_square_token
      client = create_square_client(Current.account.square_access_token)
    end

    Current.account.locations.where.not(square_location_id: nil).each do |location|
      next unless location
  
      response = client.inventory.list_inventory_counts(
        location_ids: [location.square_location_id],
        catalog_object_types: 'ITEM'
      )
  
      if response.success?
        counter = 0

        response.data.counts.each do |count|
          product = Product.find_or_initialize_by!(sku: count.catalog_object_id)
          product.name = count.catalog_object_name
          product.save!

          inv_item = InventoryItem.find_or_initialize_by(
            product: product,
            location: location
          )

          inv_item.quantity = count.quantity.to_i
          inv_item.save!
          counter += 1
        end
      else
        Rails.logger.error("Square inventory sync failed for location #{location.square_location_id}: #{response.errors}")
      end
    end

    redirect_to inventory_items_path, notice: t('notifications.inventory_synced', size: counter)
  end

  private

  def oauth_authorize_url
    client_id = ENV['SQUARE_APPLICATION_ID']
    redirect_uri = square_oauth_callback_url

    "https://connect.squareup.com/oauth2/authorize?client_id=#{client_id}&scope=ITEMS_READ+INVENTORY_READ+MERCHANT_PROFILE_READ&session=false&redirect_uri=#{CGI.escape(redirect_uri)}"
  end

  def exchange_code_for_token(code)
    client = Square::Client.new(
      environment: Rails.env.production? ? 'production' : 'sandbox'
    )

    client.oauth.obtain_token(
      body: {
        client_id: ENV['SQUARE_APPLICATION_ID'],
        client_secret: ENV['SQUARE_SECRET'],
        code: code,
        grant_type: "authorization_code"
      }
    )
  end

  def create_square_client(access_token)
    Square::Client.new(
      access_token: access_token,
      environment: Rails.env.production? ? 'production' : 'sandbox'
    )
  end

  def refresh_square_token
    client = Square::Client.new(
      environment: Rails.env.production? ? 'production' : 'sandbox'
    )

    result = client.oauth.obtain_token(
      body: {
        client_id: ENV['SQUARE_APPLICATION_ID'],
        client_secret: ENV['SQUARE_SECRET'],
        refresh_token: Current.account.square_refresh_token,
        grant_type: "refresh_token"
      }
    )

    if result.success?
      Current.account.update(
        square_access_token: result.data.access_token,
        square_refresh_token: result.data.refresh_token
      )
    else
      Rails.logger.error("Failed to refresh Square token: #{result.errors}")
    end
  end

  def token_expired?(access_token)
    client = create_square_client(access_token)
    
    response = client.locations.list_locations

    if response.error && response.error[:category] == 'AUTHENTICATION_ERROR'
      return true
    end

    false
  end

  def handle_inventory_update(data)
    counts = data.dig("object", "inventory_counts") || []
  
    counts.each do |count|
      product = Product.find_by(sku: count["catalog_object_id"])
      location = Location.find_by(square_location_id: count["location_id"])
      next unless product && location
  
      inv_item = InventoryItem.find_or_initialize_by(product: product, location: location)
      inv_item.quantity = count["quantity"].to_i
      inv_item.save!
      
      location.update(updated_at: Time.current)
    end
  end
end