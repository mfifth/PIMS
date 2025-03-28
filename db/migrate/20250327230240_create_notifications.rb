class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.string :message
      t.string :notification_type
      t.boolean :read
      t.references :account

      t.timestamps
    end
  end
end
