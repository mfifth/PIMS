class AddSquareInfoToAccountsTable < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :square_access_token, :text
    add_column :accounts, :square_merchant_id, :string
  end
end
