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

        if account && account.subscription
          main_plan = nil
          extra_products = 0
          extra_locations = 0
          extra_recipes = 0
          extra_users = 0

          subscription.items.data.each do |item|
            lookup_key = item.price.lookup_key

            case lookup_key
            when /starter|plus|premium|free|trial/
              main_plan = lookup_key
            when /extra[_ ]?products/i
              extra_products += item.quantity * 10
            when /extra[_ ]?locations/i
              extra_locations += item.quantity
            when /extra[_ ]?recipes/i
              extra_recipes += item.quantity * 5
            when /extra[_ ]?users/i
              extra_users += item.quantity
            else
              Rails.logger.warn "Unknown subscription item: #{lookup_key}"
            end
          end

          account.subscription.update!(
            plan: main_plan || account.subscription.plan,
            status: subscription.status,
            started_at: Time.at(subscription.start_date),
            ends_at: Time.at(subscription.current_period_end),
            extra_products_count: extra_products,
            extra_locations_count: extra_locations,
            extra_recipes_count: extra_recipes,
            extra_users_count: extra_users
          )
        else
          Rails.logger.error "Account or subscription not found for Stripe customer: #{subscription.customer}"
        end
      rescue => e
        Rails.logger.error "Subscription update failed: #{e.message}"
        raise # Ensures Stripe knows the webhook failed (so it retries)
      end
    end
  end

  events.subscribe 'customer.subscription.deleted' do |event|
    event = event.data.object
    account = Account.find_by(stripe_customer_id: event.customer)
    if account && account.subscription
      account.subscription.update!(status: 'invalid')
    else
      Rails.logger.error "Account or subscription not found for deletion: #{event.customer}"
    end
  end

  # -----------------------------------------
  # Fallback Handler
  # -----------------------------------------
  events.all do |event|
    Rails.logger.info "Unhandled Stripe event: #{event.type}"
  end
end
