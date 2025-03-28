class AddFieldToBatchesTableForNotification < ActiveRecord::Migration[8.0]
  def change
    add_column :batches, :notification_days_before_expiration, :integer, default: 0
  end
end
