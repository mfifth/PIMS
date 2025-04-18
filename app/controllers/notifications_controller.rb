class NotificationsController < ApplicationController
  def index
    @notifications = Current.account.notifications.order(created_at: :desc)
  end

  def mark_as_read
    @notification = Current.account.notifications.find(params[:id])
    @notification.update(read: true)
    redirect_to notifications_path, notice: t('notifications.mark_as_read')
  end

  def mark_all_as_read
    @notifications = Current.account.notifications.update_all(read: true)
    redirect_to notifications_path, notice: t('notifications.mark_all_as_read')
  end
end