class Subscription < ApplicationRecord
  belongs_to :account

  PRODUCT_PLAN_LIMITS = {
    'trial' => 25,
    'free' => 10,
    'starter' => 25,
    'plus' => 50,
    'premium' => 100
  }

  USER_PLAN_LIMITS = {
    'trial' => 2,
    'free' => 1,
    'starter' => 3,
    'plus' => 3,
    'premium' => 5
  }

  LOCATION_PLAN_LIMITS = {
    'trial' => 2,
    'free' => 1,
    'starter' => 2,
    'plus' => 3,
    'premium' => 5
  }

  RECIPE_PLAN_LIMITS = {
    'trial' => 15,
    'free' => 5,
    'starter' => 15,
    'plus' => 25,
    'premium' => 50
  }

  ADDON_PRICING = {
    location: { unit: 1, price_per_unit: 10 },          # $10 per extra location
    product:  { unit: 1, price_per_unit: 1 },           # $1 per extra product
    recipe:   { unit: 5, price_per_unit: 10 },          # $10 per 5 extra recipes
    user:     { unit: 1, price_per_unit: 5 }            # $5 per extra user
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

  def total_product_limit
    base = PRODUCT_PLAN_LIMITS[plan] || 0
    base + (extra_products_count || 0)
  end

  def total_location_limit
    base = LOCATION_PLAN_LIMITS[plan] || 0
    base + (extra_locations_count || 0)
  end

  def total_recipe_limit
    base = RECIPE_PLAN_LIMITS[plan] || 0
    base + (extra_recipes_count || 0)
  end

  def total_user_limit
    base = USER_PLAN_LIMITS[plan] || 0
    base + (extra_users_count || 0)
  end

  # ----- ADD-ON CALCULATIONS -----

  def extra_locations_count
    [account.locations.count - LOCATION_PLAN_LIMITS[plan], 0].max
  end

  def extra_products_count
    [account.products.count - PRODUCT_PLAN_LIMITS[plan], 0].max
  end

  def extra_recipes_count
    [account.recipes.count - RECIPE_PLAN_LIMITS[plan], 0].max
  end

  def extra_users_count
    [account.users.count - USER_PLAN_LIMITS[plan], 0].max
  end

  def addons_cost
    location_cost = (extra_locations_count) * ADDON_PRICING[:location][:price_per_unit]
    product_cost  = (extra_products_count) * ADDON_PRICING[:product][:price_per_unit]
    recipe_cost   = ((extra_recipes_count / ADDON_PRICING[:recipe][:unit].to_f).ceil) * ADDON_PRICING[:recipe][:price_per_unit]
    user_cost     = (extra_users_count) * ADDON_PRICING[:user][:price_per_unit]

    location_cost + product_cost + recipe_cost + user_cost
  end

  def base_plan_name
    plan.humanize
  end

  def total_monthly_cost
    base_cost + addons_cost
  end

  # You would need to define this based on your Stripe or billing setup
  def base_cost
    case plan
    when 'free' then 0
    when 'starter' then 19
    when 'plus' then 49
    when 'premium' then 99
    else 0
    end
  end
end
