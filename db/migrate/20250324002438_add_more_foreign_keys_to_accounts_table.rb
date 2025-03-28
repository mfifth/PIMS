class AddMoreForeignKeysToAccountsTable < ActiveRecord::Migration[8.0]
  def change
    add_reference :accounts, :orders
    add_reference :accounts, :inventories
    add_reference :accounts, :suppliers
    add_reference :accounts, :locations
    add_reference :accounts, :products

    remove_reference :suppliers, :users
    remove_reference :locations, :users
    remove_reference :products, :users
    remove_column :location_product_capacities, :used_capacity
  end
end
