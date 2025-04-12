class Subscription < ApplicationRecord
  belongs_to :account

  PRODUCT_PLAN_LIMITS = {
    'free' => 10,
    'basic' => 100,
    'pro' => 200,
    'enterprise' => Float::INFINITY
  }

  USER_PLAN_LIMITS = {
    'free' => 2
    'basic' => 4,
    'pro' => 6,
    'enterprise' => Float::INFINITY
  }

  LOCATION_PLAN_LIMITS = {
    'free' => 1,
    'basic' => 3,
    'pro' => 6,
    'enterprise' => Float::INFINITY
  }
end
