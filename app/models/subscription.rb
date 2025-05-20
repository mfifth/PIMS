class Subscription < ApplicationRecord
  belongs_to :account

  PRODUCT_PLAN_LIMITS = {
    'trial' => 25,
    'free' => 10,
    'starter' => 25,
    'plus' => 50,
    'premium' => 100
  }.freeze

  USER_PLAN_LIMITS = {
    'trial' => 1,
    'free' => 1,
    'starter' => 2,
    'plus' => 3,
    'premium' => 4
  }.freeze

  LOCATION_PLAN_LIMITS = {
    'trial' => 1,
    'free' => 1,
    'starter' => 1,
    'plus' => 2,
    'premium' => 4
  }.freeze

  RECIPE_PLAN_LIMITS = {
    'trial' => 10,
    'free' => 3,
    'starter' => 10,
    'plus' => 20,
    'premium' => 30
  }.freeze

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

  def has_any_addons?
    extra_products_count.to_i > 0 ||
    extra_locations_count.to_i > 0 ||
    extra_recipes_count.to_i > 0 ||
    extra_users_count.to_i > 0
  end

  def base_plan_name
    plan.humanize
  end

  def upgrade_to_trial!
    update!(
      plan: 'trial',
      status: 'active',
      started_at: Time.current,
      ends_at: 1.month.from_now
    )
  end
end