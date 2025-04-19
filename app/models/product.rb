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

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :perishable, inclusion: { in: [true, false] }
  validates :price, numericality: { greater_than: 0 }
  validate :product_limit_not_exceeded, on: :create

  scope :perishable, -> { where(perishable: true) }

  before_save :update_perishable_status, if: :will_save_change_to_batch_id?

  private

  def product_limit_not_exceeded
    if account.products.count >= Subscription::PRODUCT_PLAN_LIMITS[account.subscription.plan]
      errors.add(:base, t('notifications.product_limit_warning', limit: Subscription::PRODUCT_PLAN_LIMITS[account.subscription.plan]))
    end
  end

  def update_perishable_status
    self.perishable = batch.present?
  end
end