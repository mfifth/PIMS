class Order < ApplicationRecord
  belongs_to :account
  belongs_to :location, optional: true
  has_many :order_items, dependent: :destroy

  accepts_nested_attributes_for :order_items, allow_destroy: true

  before_save :calculate_total

  def calculate_total
    self.total = order_items.sum { |item| item.quantity.to_i * item.price.to_f }
  end
end
