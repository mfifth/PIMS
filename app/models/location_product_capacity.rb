class LocationProductCapacity < ApplicationRecord
  belongs_to :location
  belongs_to :product

  validates :capacity, numericality: { greater_than_or_equal_to: 0 } # Max capacity allowed for this product
  validates :used_capacity, numericality: { greater_than_or_equal_to: 0 } # How much of the capacity is used

  # Calculate available capacity for this product at this location
  def available_capacity
    capacity - used_capacity
  end

  # Method to check if adding more stock is possible for this product
  def can_add_more?(quantity)
    available_capacity >= quantity
  end
end
