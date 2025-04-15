class Account < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :locations, dependent: :destroy
  has_many :suppliers, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :batches, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :invitations
  has_one :subscription

  def stripe_plan_id
    'free'
    # Stripe::Subscription.retrieve(subscription.stripe_subscription_id).items.data.first.price.id
  end
end
