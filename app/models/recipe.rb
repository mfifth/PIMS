class Recipe < ApplicationRecord
  belongs_to :account
  has_many :recipe_items, dependent: :destroy
  has_many :products, through: :recipe_items

  accepts_nested_attributes_for :recipe_items, allow_destroy: true

  validates :uid, presence: true, uniqueness: { scope: :account_id }
  validates :name, presence: true, uniqueness: { scope: :account_id }
  validate :recipe_limit_not_exceeded, on: :create

  private

  def recipe_limit_not_exceeded
    if account.recipes.count >= Subscription::RECIPE_PLAN_LIMITS[account.subscription.plan]
      errors.add(:base, I18n.t('notifications.recipe_limit_warning', limit: Subscription::RECIPE_PLAN_LIMITS[account.subscription.plan]))
    end
  end
end
  