class RemoveOrdersFromAccounts < ActiveRecord::Migration[8.0]
  def change
    drop_table :orders
  end
end
