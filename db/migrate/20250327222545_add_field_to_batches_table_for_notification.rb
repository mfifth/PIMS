class AddFieldToBatchesTableForNotification < ActiveRecord::Migration[8.0]
  def change
    add_column :batches, :integer, :notification_days_before_expiration
  end
end
