class Location < ApplicationRecord
  has_many :inventory_items, dependent: :destroy
  has_many :products, through: :inventory_items
  belongs_to :account

  has_many :location_product_capacities, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :address, presence: true
end
