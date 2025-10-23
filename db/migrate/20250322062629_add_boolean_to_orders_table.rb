class AddBooleanToOrdersTable < ActiveRecord::Migration[8.0]
  def up
    return unless table_exists?(:orders)
    return if column_exists?(:orders, :replenish_on_arrival)

    add_column :orders, :replenish_on_arrival, :boolean, default: false
  end

  def down
    return unless table_exists?(:orders)
    return unless column_exists?(:orders, :replenish_on_arrival)

    remove_column :orders, :replenish_on_arrival
  end
end
