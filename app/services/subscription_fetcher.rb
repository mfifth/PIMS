class SubscriptionFetcher
  def self.plan_name_for(subscription_id)
    Stripe::Subscription.retrieve(subscription_id).plan.id
  end
end