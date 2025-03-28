class AddReferenceToUsersForAccounts < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :account
  end
end
