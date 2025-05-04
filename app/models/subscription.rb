class Subscription < ApplicationRecord
  belongs_to :account

  PRODUCT_PLAN_LIMITS = {
    'trial' => 50,
    'free' => 20,
    'starter' => 50,
    'plus' => 100,
    'premium' => Float::INFINITY
  }

  USER_PLAN_LIMITS = {
    'trial' => 2,
    'free' => 1,
    'starter' => 3,
    'plus' => 5,
    'premium' => Float::INFINITY
  }

  LOCATION_PLAN_LIMITS = {
    'trial' => 2,
    'free' => 1,
    'starter' => 2,
    'plus' => 4,
    'premium' => Float::INFINITY
  }

  def expired?
    ends_at.present? && Time.current >= ends_at
  end

  def trialing?
    plan == "trial" && status == "active"
  end

  def active?
    status == "active" && (ends_at.nil? || Time.current < ends_at)
  end
end