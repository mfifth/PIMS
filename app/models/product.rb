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
  validates :perishable, inclusion: { in: [true, false] }
  validate :product_limit_not_exceeded, on: :create

  scope :perishable, -> { where(perishable: true) }

  private

  def product_limit_not_exceeded
    if account.products.count >= PRODUCT_PLAN_LIMITS[account.subscription.plan]
      errors.add(:base, "You have reached the maximum limit of #{PRODUCT_PLAN_LIMITS[account.subscription.plan]} products.")
    end
  end
end