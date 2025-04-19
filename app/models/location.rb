class Location < ApplicationRecord
  has_many :inventory_items, dependent: :destroy
  has_many :products, through: :inventory_items
  belongs_to :account

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validate :location_limit_not_exceeded, on: :create

  private

  def location_limit_not_exceeded
    return unless account.locations.count >= 
    Subscription::LOCATION_PLAN_LIMITS[account.subscription.plan]

    errors.add(:base, I18n.t('notifications.location_limit_warning', 
    limit: Subscription::LOCATION_PLAN_LIMITS[account.subscription.plan]))
  end
end
