class Subscription < ApplicationRecord
  belongs_to :account

  PRODUCT_PLAN_LIMITS = {
    'free' => 25,
    'pro' => 100,
    'enterprise' => Float::INFINITY
  }

  USER_PLAN_LIMITS = {
    'free' => 1,
    'pro' => 2,
    'enterprise' => Float::INFINITY
  }

  LOCATION_PLAN_LIMITS = {
    'free' => 1,
    'pro' => 2,
    'enterprise' => Float::INFINITY
  }
end
