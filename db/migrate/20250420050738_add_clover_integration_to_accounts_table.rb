class AddCloverIntegrationToAccountsTable < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :clover_access_token, :string
    add_column :accounts, :clover_merchant_id, :string
  end
end
