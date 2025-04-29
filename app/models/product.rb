class Product < ApplicationRecord
  attr_reader :low_threshold
  attr_accessor :category_name

  belongs_to :supplier, optional: true
  belongs_to :account
  belongs_to :batch, optional: true
  belongs_to :category, optional: true

  has_many :inventory_items, dependent: :destroy
  has_many :location_product_capacities, dependent: :destroy
  has_many :locations, through: :inventory_items
  has_many :recipe_items, dependent: :destroy

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: { scope: [:account_id] }
  validates :perishable, inclusion: { in: [true, false] }
  validate :product_limit_not_exceeded, on: :create

  scope :perishable, -> { where(perishable: true) }

  before_save :update_perishable_status, if: :will_save_change_to_batch_id?
  validate :check_recipe_usage_before_deletion, on: :destroy

  def self.unit_options
    VALID_UNITS.map { |u| [u.humanize, u] }
  end

  VALID_UNITS = %w[grams ounces pounds liters gallons fluid_oz milliliters units].freeze

  private

  def product_limit_not_exceeded
    if account.products.count >= Subscription::PRODUCT_PLAN_LIMITS[account.subscription.plan]
      errors.add(:base, t('notifications.product_limit_warning', limit: Subscription::PRODUCT_PLAN_LIMITS[account.subscription.plan]))
    end
  end

  def update_perishable_status
    self.perishable = batch.present?
  end

  def check_recipe_usage_before_deletion
    if recipe_items.any?
      errors.add(:base, "Cannot delete product used in recipes")
      throw :abort
    end
  end
end