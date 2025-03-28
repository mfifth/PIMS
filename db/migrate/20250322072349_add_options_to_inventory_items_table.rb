class AddOptionsToInventoryItemsTable < ActiveRecord::Migration[8.0]
  def change
    add_column :inventory_items, :daily_usage, :integer
    add_column :inventory_items, :low_threshold, :integer
  end
end
