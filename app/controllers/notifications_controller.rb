class NotificationsController < ApplicationController
  def index
    @notifications = Current.account.notifications.order(created_at: :desc)
  end

  def mark_as_read
    @notification = Current.account.notifications.find(params[:id])
    @notification.update(read: true)
    redirect_to notifications_path, notice: "Notification marked as read."
  end
end