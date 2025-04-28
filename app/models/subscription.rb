class Subscription < ApplicationRecord
  belongs_to :account

  PRODUCT_PLAN_LIMITS = {
    'free' => 25,
    'starter' => 50,
    'plus' => 100,
    'premium' => Float::INFINITY
  }

  USER_PLAN_LIMITS = {
    'free' => 1,
    'starter' => 3,
    'plus' => 5,
    'premium' => Float::INFINITY
  }

  LOCATION_PLAN_LIMITS = {
    'free' => 1,
    'starter' => 2,
    'plus' => 4,
    'premium' => Float::INFINITY
  }
end