class Location < ApplicationRecord
  has_many :inventory_items, dependent: :destroy
  has_many :products, through: :inventory_items
  has_many :orders

  belongs_to :account

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validate :location_limit_not_exceeded, on: :create

  private

  def location_limit_not_exceeded
    current_limit = account.subscription.total_location_limit
    return unless account.locations.count >= current_limit

    errors.add(:base, I18n.t('notifications.location_limit_warning', limit: current_limit))
  end
end
