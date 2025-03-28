class AddSettingsToAccountsTable < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :text_notification, :boolean, default: false
    add_column :accounts, :email_notification, :boolean, default: false
  end
end
