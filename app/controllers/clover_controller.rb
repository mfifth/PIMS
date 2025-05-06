class CloverController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :webhook

  CLIENT_ID     = ENV['CLOVER_CLIENT_ID']
  CLIENT_SECRET = ENV['CLOVER_CLIENT_SECRET']
  REDIRECT_URI  = 'https://pimsco.tech/clover/oauth/callback'

  def start
    session[:current_account_id] = Current.account.id
    url = "https://www.clover.com/oauth/authorize?client_id=#{CLIENT_ID}&response_type=code&redirect_uri=#{REDIRECT_URI}"
    redirect_to url, allow_other_host: true
  end

  def callback
    if params[:code].present?
      response = Faraday.post('https://www.clover.com/oauth/token') do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = {
          client_id:     CLIENT_ID,
          client_secret: CLIENT_SECRET,
          code:          params[:code],
          redirect_uri:  REDIRECT_URI
        }.to_query
      end

      if response.success?
        data = JSON.parse(response.body)
        account = Account.find(session.delete(:current_account_id))
        account.update!(
          clover_access_token: data['access_token'],
          clover_merchant_id: data['merchant_id']
        )

        if register_clover_webhook(account)
          redirect_to dashboard_path, notice: "Clover connected successfully!"
        else
          redirect_to dashboard_path, alert: "Clover connected but webhook registration failed"
        end
      else
        Rails.logger.error "Clover OAuth Error: #{response.body}"
        redirect_to dashboard_path, alert: "Failed to connect with Clover"
      end
    else
      redirect_to dashboard_path, alert: "Authorization failed: no code received"
    end
  end

  def webhook
    event = JSON.parse(request.body.read)

    merchant_id = event["merchantId"]
    type        = event["type"]
    entity_id   = event["objectId"]

    account = Account.find_by(clover_merchant_id: merchant_id)
    return head :not_found unless account

    case type
    when "ORDER.created"
      CloverOrderSyncJob.perform_later(account.id, entity_id)
    when "ITEM.updated", "ITEM.created"
      CloverItemSyncJob.perform_later(account.id, entity_id)
    end

    head :ok
  end

  def sync_data
    CloverSyncJob.perform_later(Current.account.id)
    redirect_to root_path, notice: "Sync started! Products will update shortly."
  end  
end
