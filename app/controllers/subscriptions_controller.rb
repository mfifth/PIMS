class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def new
    # Show subscription plans to the user
  end

  def create
    # Ensure user has a Stripe Customer ID
    unless current_user.stripe_customer_id
      # Create a Stripe customer if it doesn't exist
      customer = Stripe::Customer.create(
        email: current_user.email,
        name: current_user.name
      )
      current_user.update(stripe_customer_id: customer.id)
    end

    # Create a checkout session
    session = Stripe::Checkout::Session.create({
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency: 'usd',
          product_data: {
            name: 'Monthly Subscription',
          },
          unit_amount: 1000, # Price in cents (e.g., $10.00)
        },
        quantity: 1,
      }],
      mode: 'subscription',
      success_url: subscription_success_url,
      cancel_url: subscription_cancel_url,
      customer: current_user.stripe_customer_id
    })

    redirect_to session.url
  end

  def success
    # Subscription was successful
    # Record the subscription in the database and activate it
    current_user.update(subscription_active: true)

    # Create a Subscription record
    Subscription.create!(
      user: current_user,
      stripe_subscription_id: session.subscription,
      plan: 'monthly',
      status: 'active',
      started_at: Time.current,
      ends_at: Time.current + 1.month
    )
    redirect_to dashboard_path, notice: 'Subscription successful!'
  end

  def cancel
    # Handle when the user cancels the subscription
    redirect_to dashboard_path, alert: 'Subscription canceled.'
  end
end
