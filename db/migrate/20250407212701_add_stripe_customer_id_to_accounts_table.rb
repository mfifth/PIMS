class AddStripeCustomerIdToAccountsTable < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :stripe_customer_id, :string
  end
end
