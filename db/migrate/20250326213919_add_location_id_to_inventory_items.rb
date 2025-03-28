class AddLocationIdToInventoryItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :inventory_items, :location
  end
end
