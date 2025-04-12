class Location < ApplicationRecord
  has_many :inventory_items, dependent: :destroy
  has_many :products, through: :inventory_items
  belongs_to :account

  has_many :location_product_capacities, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :address, presence: true

  validate :location_limit_not_exceeded, on: :create

  private

  def location_limit_not_exceeded
    if account.locations.count >= LOCATION_PLAN_LIMITS[account.subscription.plan]
      errors.add(:base, "You have reached the maximum limit of #{LOCATION_PLAN_LIMITS[account.subscription.plan]} locations.")
    end
  end
end
