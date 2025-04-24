class RemoveOrdersFromAccounts < ActiveRecord::Migration[8.0]
  if ActiveRecord::Base.connection.table_exists? 'orders'
    def change
      drop_table :orders, force: :cascade
    end
  end
end
