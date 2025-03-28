class DropReferencesToInventory < ActiveRecord::Migration[8.0]
  def change
    remove_reference :inventories, :location
    remove_reference :accounts, :inventories
    remove_reference :inventory_items, :inventory
    add_reference :locations, :inventory_items
  end
end
