class MoveEmailTextPreferencesFromAccountsToUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :accounts, :email_notification
    remove_column :accounts, :text_notification

    add_column :users, :text_notification, :boolean, default: false
    add_column :users, :email_notification, :boolean, default: false
  end
end
