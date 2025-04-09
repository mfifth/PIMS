class Account < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :orders, dependent: :destroy
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

  def product_plan_limit
    20
    # PRODUCT_PLAN_LIMITS[stripe_plan_id] || 0
  end

  def user_plan_limit
    3
    # USER_PLAN_LIMITS[stripe_plan_id] || 0
  end

  def can_create_product?
    products.count < product_plan_limit
  end

  def can_create_user?
    users.count < user_plan_limit
  end

  PRODUCT_PLAN_LIMITS = {
    'basic' => 50,
    'pro' => 100,
    'enterprise' => Float::INFINITY,
    'free' => 10
  }

  USER_PLAN_LIMITS = {
    'basic' => 3,
    'pro' => 6,
    'enterprise' => Float::INFINITY,
    'free' => 2
  }
end
