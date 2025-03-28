class AddAccountsIdToOtherTables < ActiveRecord::Migration[8.0]
  def change
    add_reference :suppliers, :account
    add_reference :locations, :account
    add_reference :products, :account
  end
end
