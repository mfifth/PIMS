class Product < ApplicationRecord
  attr_reader :low_threshold

  belongs_to :supplier, optional: true
  belongs_to :account
  belongs_to :batch, optional: true

  has_many :inventory_items, dependent: :destroy
  has_many :location_product_capacities, dependent: :destroy
  has_many :locations, through: :inventory_items

  validates :name, presence: true
  validates :perishable, inclusion: { in: [true, false] }
end