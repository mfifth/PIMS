class BillingController < ApplicationController
  def create_checkout_session
    session = Stripe::Checkout::Session.create(
      customer: Current.account.stripe_customer_id,
      payment_method_types: ['card'],
      line_items: [{
        price: 'price_1RBNjRHCh3i3bWdKQTqmufyF', # <-- Your Stripe Price ID
        quantity: 1
      }],
      mode: 'subscription',
      success_url: 'subscriptions/success' + "?checkout=success",
      cancel_url: 'subscriptions/cancel' + "?checkout=cancel"
    )

    redirect_to session.url, allow_other_host: true
  end

  def billing_portal
    portal_session = Stripe::BillingPortal::Session.create({
      customer: Current.account.stripe_customer_id,
      return_url: root_url,
    })
  
    redirect_to portal_session.url, allow_other_host: true
  end
end
