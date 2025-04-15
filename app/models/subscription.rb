class Subscription < ApplicationRecord
  belongs_to :account

  PRODUCT_PLAN_LIMITS = {
    'free' => 25,
    'basic' => 50,
    'pro' => 100,
    'enterprise' => Float::INFINITY
  }

  USER_PLAN_LIMITS = {
    'free' => 1,
    'basic' => 2,
    'pro' => 3,
    'enterprise' => Float::INFINITY
  }

  LOCATION_PLAN_LIMITS = {
    'free' => 1,
    'basic' => 2,
    'pro' => 4,
    'enterprise' => Float::INFINITY
  }
end
