class AddPriceToInventoryItems < ActiveRecord::Migration[8.0]
  def change
    add_column :inventory_items, :price, :decimal, precision: 10, scale: 2, default: 0.0
  end
end
