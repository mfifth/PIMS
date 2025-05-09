class SquareController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :webhook
  skip_before_action :require_authentication, only: :webhook

  before_action do
    response.headers['X-Frame-Options'] = 'DENY'
  end

  before_action :verify_square_webhook_signature, only: :webhook

  def start
    session[:current_account_id] = Current.account.id
    state = SecureRandom.hex(24)
    session[:square_oauth_state] = state
    redirect_to oauth_authorize_url(state: state), allow_other_host: true
  end

  def callback
    return redirect_to root_path, alert: "Missing authorization code" unless params[:code].present?

    result = exchange_code_for_token(params[:code])

    if result.success?
      data = result.data
      account = Account.find(session.delete(:current_account_id))
      account.update!(
        square_access_token: data.access_token,
        square_refresh_token: data.refresh_token,
        square_merchant_id: data.merchant_id
      )

      redirect_to dashboard_path, notice: t('notifications.square_account_connected')
    else
      redirect_to root_path, alert: t('notifications.oauth_failed')
    end
  rescue Square::ApiError => e
    Rails.logger.error("Square OAuth failed: #{e.message}")
    redirect_to root_path, alert: "Square connection failed"
  end

  def webhook
    event = JSON.parse(request.body.read)
    merchant_id = event.dig("merchant_id")
    type        = event["event_type"]
    data        = event["data"]

    account = Account.find_by(square_merchant_id: merchant_id)
    return head :not_found unless account

    case type
    when "inventory.count.updated"
      SquareInventorySyncJob.perform_later(account.id, data)
    when "order.created", "order.updated"
      SquareOrderProcessingJob.perform_later(account.id, data)
    else
      Rails.logger.info("Received unsupported event type: #{type}")
    end

    head :ok
  end

  def sync_data
    SquareSyncJob.perform_later(Current.account.id)
    redirect_to root_path, notice: t('accounts_settings.square.sync_started')
  end

  private

  def oauth_authorize_url(state)
    uri = URI("https://connect.squareup.com/oauth2/authorize")
    uri.query = {
      client_id: ENV['SQUARE_APPLICATION_ID'],
      scope: "ITEMS_READ INVENTORY_READ",
      state: state,
      redirect_uri: square_oauth_callback_url
    }.to_query
    uri.to_s
  end

  def exchange_code_for_token(code)
    Square::Client.new(environment: Rails.env.production? ? 'production' : 'sandbox')
                  .oauth
                  .obtain_token(
                    body: {
                      client_id: ENV['SQUARE_APPLICATION_ID'],
                      client_secret: ENV['SQUARE_SECRET'],
                      code: code,
                      grant_type: "authorization_code"
                    }
                  )
  end

  def verify_square_webhook_signature
    signature = request.headers['X-Square-Signature']
    return head :unauthorized unless signature

    request.body.rewind
    payload = request.body.read

    signature_key = ENV['SQUARE_WEBHOOK_SIGNATURE_KEY']
    return head :unauthorized unless signature_key

    notification_url = request.original_url
    string_to_sign = notification_url + payload

    expected_signature = Base64.strict_encode64(
      OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), signature_key, string_to_sign)
    )

    unless ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
      Rails.logger.error "Invalid Square webhook signature"
      head :unauthorized
    end
  end
end
