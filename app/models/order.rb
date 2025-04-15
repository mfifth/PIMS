class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy

  belongs_to :user
  belongs_to :account
  belongs_to :supplier

  # Add relevant fields to the order (e.g., user_id, status, total_amount, etc.)
  validates :status, presence: true
  validates :total_amount, presence: true

  after_update :update_inventory, if: :saved_change_to_status?

  def update_inventory
    inventory = Inventory.includes(:inventory_items).find_by(location: location)
    return unless (inventory && status == 'Completed') || replenish_on_arrival && arrival_date.past?
    order_items.each do |order_item|
      inventory.inventory_items.find_or_create_by(product: order_item.product).update(quantity: order_item.quantity)
    end
  end
end
