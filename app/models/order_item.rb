class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :batch, optional: true
  belongs_to :location

  # Add fields like quantity, price, etc.
  validates :quantity, presence: true, numericality: { greater_than: 0 }
end