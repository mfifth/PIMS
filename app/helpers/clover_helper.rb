module CloverHelper
	def register_clover_webhook(account)
	  return false unless account.clover_access_token && account.clover_merchant_id
  
	  url = "https://api.clover.com/v3/merchants/#{account.clover_merchant_id}/webhooks"
	  
	  response = Faraday.post(url) do |req|
		req.headers["Authorization"] = "Bearer #{account.clover_access_token}"
		req.headers["Content-Type"] = "application/json"
		req.body = {
		  url: 'https://pimsco.tech/webhooks/clover',
		  type: "ITEM.updated,ITEM.created,ORDER.created"
		}.to_json
	  end
  
	  response.success?
	rescue Faraday::Error => e
	  Rails.logger.error "Clover webhook registration failed: #{e.message}"
	  false
	end
end