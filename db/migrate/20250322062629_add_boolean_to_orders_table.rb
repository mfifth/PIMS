class AddBooleanToOrdersTable < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :replenish_on_arrival, :boolean, default: false
  end
end
