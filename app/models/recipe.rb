class Recipe < ApplicationRecord
  belongs_to :account
  has_many :recipe_items, dependent: :destroy
  has_many :products, through: :recipe_items
  has_many :order_items, as: :item, dependent: :restrict_with_error

  accepts_nested_attributes_for :recipe_items, allow_destroy: true

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validate :recipe_limit_not_exceeded, on: :create

  def estimated_cost(location)
    recipe_items.sum do |item|
      inventory_item = item.product.inventory_items.where(location: location).first
      next item.product.price.to_f * item.quantity unless inventory_item
      
      conversion_rate = RecipeItem::CONVERSION_RATES.dig(item.unit, inventory_item.unit_type)
      next item.product.price.to_f * item.quantity unless conversion_rate
      
      adjusted_quantity = item.quantity * conversion_rate
      adjusted_quantity * inventory_item.price
    end
  end

  private

  def recipe_limit_not_exceeded
    current_limit = account.subscription.total_recipe_limit
    if account.recipes.count >= current_limit
      errors.add(:base, I18n.t('notifications.recipe_limit_warning', limit: current_limit))
    end
  end
end
  