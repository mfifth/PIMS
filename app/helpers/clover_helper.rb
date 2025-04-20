module CloverHelper
	def register_clover_webhook(account)
		url = "https://api.clover.com/v3/merchants/#{account.clover_merchant_id}/webhooks"
	
		Faraday.post(url) do |req|
			req.headers["Authorization"] = "Bearer #{account.clover_access_token}"
			req.headers["Content-Type"] = "application/json"
			req.body = {
				url: "https://pimsco.tech/webhooks/clover",
				type: "ITEM.updated, ORDER.created, ITEM.created" # You can register multiple like ITEM.created, ORDER.created, etc.
			}.to_json
		end
	end
end
