class Subscription < ApplicationRecord
  belongs_to :account

  PRODUCT_PLAN_LIMITS = {
    'free' => 25,
    'plus' => 100,
    'premium' => Float::INFINITY
  }

  USER_PLAN_LIMITS = {
    'free' => 1,
    'plus' => 2,
    'premium' => Float::INFINITY
  }

  LOCATION_PLAN_LIMITS = {
    'free' => 1,
    'plus' => 2,
    'premium' => Float::INFINITY
  }
end
