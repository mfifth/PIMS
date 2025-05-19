# app/controllers/billing_controller.rb
class BillingController < ApplicationController
  before_action :require_authentication
  before_action :verify_stripe_customer

  def billing_portal
    begin
      portal_session = Stripe::BillingPortal::Session.create(
        {
          customer: Current.account.stripe_customer_id,
          locale: I18n.locale.to_s,
          return_url: Rails.application.routes.url_helpers.settings_user_url(
            Current.user,
            host: ENV.fetch('APP_HOST', 'localhost:3000'),
            protocol: Rails.env.production? ? 'https' : 'http'
          )
        }
      )
      
      redirect_to portal_session.url, allow_other_host: true, status: :see_other
      
    rescue Stripe::InvalidRequestError => e
      Rails.logger.error "Stripe Error: #{e.message}"
      redirect_to settings_user_path(Current.user), 
                  alert: "Billing portal unavailable. Please contact support."
                  
    rescue Stripe::StripeError => e
      redirect_to settings_user_path(Current.user), 
                  alert: "We're experiencing billing system issues. Our team has been notified."
    end
  end

  private

  def verify_stripe_customer
    unless Current.account.stripe_customer_id.present?
      redirect_to settings_user_path(Current.user), 
                  alert: "No subscription found. Please create a subscription first."
    end
  end
end