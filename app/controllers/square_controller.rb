require 'base64'
require 'openssl'

class SquareController < ApplicationController
	skip_before_action :verify_authenticity_token

	def webhook
    signature = request.headers['X-Square-Signature']
    body = request.body.read
    signature_key = ENV['SQUARE_WEBHOOK_SIGNATURE_KEY']
    endpoint_url = webhook_endpoint_url

    unless valid_signature?(signature, signature_key, body, endpoint_url)
      Rails.logger.warn "Square webhook signature mismatch"
      return head :unauthorized
    end

    payload = JSON.parse(body)

    if payload['type'] == 'order.created'
      order_id = payload.dig('data', 'object', 'order', 'id')
			square_location_id = params.dig('data', 'object', 'order', 'location_id')
      process_order(order_id, square_location_id)
    end

    head :ok
  end

	private

	def valid_signature?(signature, key, body, url)
    digest = OpenSSL::Digest.new('sha1')
    string_to_sign = url + body
    computed_signature = Base64.strict_encode64(OpenSSL::HMAC.digest(digest, key, string_to_sign))
    ActiveSupport::SecurityUtils.secure_compare(signature, computed_signature)
  end

  def webhook_endpoint_url
    "https://pimsco.tech/square/webhook"
  end

	def process_order(order_id, square_location_id)
  	location = Location.find_by(square_location_id: square_location_id)
		account = location.account
  	return head :not_found unless location

    client = Square::Client.new(
      access_token: account.square_access_token,
      environment: 'production' # or 'production'
    )

    response = client.orders.retrieve_order(order_id: order_id)

    if response.success?
      order = response.data.order
      order.line_items.each do |line_item|
        update_inventory(line_item, location)
      end
    else
      Rails.logger.error "Failed to fetch Square order #{order_id}: #{response.errors}"
    end
  end

  def update_inventory(line_item, location)
    product = Product.find_by(sku: line_item.catalog_object_id.to_s, account_id: location.account.id)
		inventory_item = InventoryItem.find_by(location: location.id, product_id: product.id)
    return unless inventory_item

    quantity_sold = line_item.quantity.to_i
    inventory_item.update(quantity: inventory_item.quantity - quantity_sold)
  end
end