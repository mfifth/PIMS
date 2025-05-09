class ExpirationNotificationJob < ApplicationJob
  queue_as :default

  def perform
    today = Date.current

    Batch.where.not(expiration_date: nil, notification_days_before_expiration: 0)
    .find_each do |batch|
      notify_date = batch.expiration_date - batch.notification_days_before_expiration.days

      next unless today == notify_date

      text = t('notifications.batch_expiry', 
               batch_number: batch.batch_number, 
               product_count: batch.products.count, 
               expiration_date: batch.expiration_date)

      accounts = batch.products.includes(:accounts).map(&:accounts).flatten.uniq
      users = accounts.flat_map(&:users).uniq

      accounts.each do |account|
        Notification.create(
          message: text,
          notification_type: "Alert",
          account_id: account.id
        )
      end

      users.each do |user|
        if user.email_notification
          NotificationMailer.upcoming_expiration_date(user, batch).deliver_later
        end

        if user.text_notification && user.phone
          NotificationService.send_sms(user.phone, text)
        end
      end
    end
  end
end
