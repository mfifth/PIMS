class Order < ApplicationRecord
  belongs_to :account
  belongs_to :location, optional: true
  has_many :order_items, dependent: :destroy

  accepts_nested_attributes_for :order_items, allow_destroy: true

  def calculate_total
    order_items.sum(&:subtotal)
  end

  before_save :recalculate_total

  private

  def recalculate_total
    self.total = order_items.reject(&:marked_for_destruction?).sum do |item|
      item.price.to_f * item.quantity.to_i
    end
  end
end
