class ExpirationNotificationJob < ApplicationJob
  queue_as :default

  def perform
    today = Date.current

    Batch.where.not(expiration_date: nil).find_each do |batch|
      next unless batch.notification_days_before_expiration.present?

      notify_date = batch.expiration_date - batch.notification_days_before_expiration.days
      text = t('notifications.batch_expiry', batch_number: batch.batch_number, 
      product_count: batch.products.count, expiration_date: batch.expiration_date)

      if today == notify_date
        batch.products.each do |product|
          product.accounts.distinct.each do |account|
            Notification.create(
              message: text,
              notification_type: "Alert",
              account_id: account.id
            )
            account.users.each do |user|
              NotificationMailer.upcoming_expiration_date(user, batch).deliver_later if user.email_notification
              NotificationService.send_sms(user.phone, text) if user.text_notification && user.phone
            end
          end
        end
      end
    end
  end
end
