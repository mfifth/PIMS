class ExpirationNotificationJob < ApplicationJob
  queue_as :default

  def perform
    today = Date.current

    Batch.where.not(expiration_date: nil).find_each do |batch|
      next unless batch.notification_days_before_expiration.present?

      notify_date = batch.expiration_date - batch.notification_days_before_expiration.days
      text = "Batch ##{batch.batch_number} with #{batch.products.count} products at is expiring soon (#{batch.expiration_date})"

      # Only send notifications if the expiration date is today
      if today == notify_date
        batch.products.each do |product|
          # Loop through each account associated with the batch and send the email to each user in that account
          product.accounts.distinct.each do |account|
            Notification.create(
              message: text,
              notification_type: "Alert",
              account_id: account.id
            )
            # Assuming an account has many users, we will send the email to each user individually
            account.users.each do |user|
              NotificationMailer.upcoming_expiration_date(user, batch).deliver_later if user.email_notification
              NotificationService.send_sms(user.phone, text) if user.text_notification
            end
          end
        end
      end
    end
  end
end
