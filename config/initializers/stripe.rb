Stripe.api_key = ENV['STRIPE_SECRET_KEY']
StripeEvent.signing_secret = ENV['STRIPE_SIGNING_SECRET']

StripeEvent.configure do |events|
  # -----------------------------------------
  # Subscription Events
  # -----------------------------------------
  events.subscribe 'customer.subscription.updated' do |event|
    ActiveRecord::Base.connection_pool.with_connection do
      begin
        subscription = event.data.object
        account = Account.find_by(stripe_customer_id: subscription.customer)
        
        if account
          account.subscription.update!(
            plan: subscription.items.data[0].price.lookup_key,
            status: account.subscription.update(status: subscription.status),
						started_at: Time.current,
						ends_at: Time.at(subscription.current_period_end)
          )
        else
          Rails.logger.error "Account not found for Stripe customer: #{subscription.customer}"
        end
      rescue => e
        Sentry.capture_exception(e) # Or your error tracker
        Rails.logger.error "Subscription update failed: #{e.message}"
        raise # Ensures Stripe knows the webhook failed
      end
    end
  end

  events.subscribe 'customer.subscription.deleted' do |event|
    event = event.data.object
    Account.find_by(stripe_customer_id: event.customer).update!(status: 'invalid')
  end

  # -----------------------------------------
  # Fallback Handler
  # -----------------------------------------
  events.all do |event|
    Rails.logger.info "Unhandled Stripe event: #{event.type}"
  end
end