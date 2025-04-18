class AddSquareRefreshTokenToAccountsTable < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :square_refresh_token, :string
  end
end
