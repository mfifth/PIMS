class AddReplenishOnArrivalToOrders < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:orders, :replenish_on_arrival)
      add_column :orders, :replenish_on_arrival, :boolean, default: false
    end

    unless foreign_key_exists?(:order_items, :orders)
      add_foreign_key :order_items, :orders
    end
  end

  def down
    remove_foreign_key :order_items, :orders if foreign_key_exists?(:order_items, :orders)
    remove_column :orders, :replenish_on_arrival if column_exists?(:orders, :replenish_on_arrival)
  end
end
