class RemoveOrderIdFromAccountsTable < ActiveRecord::Migration[8.0]
  def change
    remove_column :accounts, :orders_id
  end
end
