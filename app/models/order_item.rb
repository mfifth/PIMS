class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :location
  belongs_to :item, polymorphic: true

  before_validation :populate_price_from_inventory

  def populate_price_from_inventory
    self.price ||= inventory_item.price
  end
end
