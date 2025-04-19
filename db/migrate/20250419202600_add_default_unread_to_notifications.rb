class AddDefaultUnreadToNotifications < ActiveRecord::Migration[8.0]
  def change
    change_column_default :notifications, :read, from: nil, to: false
  end
end
