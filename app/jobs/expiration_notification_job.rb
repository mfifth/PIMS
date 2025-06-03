class ExpirationNotificationJob < ApplicationJob
  queue_as :default

  def perform
    today = Date.current

    Batch.joins(:inventory_items)
         .where.not(expiration_date: nil)
         .where("expiration_date >= ?", today)
         .where("notification_days_before_expiration > 0")
         .distinct
         .find_each do |batch|

      notification_date = batch.expiration_date.to_date - batch.notification_days_before_expiration.days
      next unless today >= notification_date

      inventory_items = batch.inventory_items.includes(:product, :location)
      next if inventory_items.empty?

      inventory_items.group_by { |i| i.product.account }.each do |account, items|
        send_account_notifications(account, batch, items)
      end
    end
  end

  private

  def send_account_notifications(account, batch, inventory_items)
    items_by_location = inventory_items.group_by(&:location)
    message = build_notification_message(batch, items_by_location)

    Notification.create(
      message: message,
      notification_type: "batch_expiration",
      account_id: account.id
    )

    account.users.each do |user|
      send_user_notifications(user, batch, message)
    end
  end

  def build_notification_message(batch, items_by_location)
    all_items = items_by_location.values.flatten

    locations_list = items_by_location.map do |location, items|
      total_quantity = items.sum(&:quantity)
      "#{location.name} (#{total_quantity} #{items.first.unit_type})"
    end.join(", ")

    I18n.t('notifications.batch_expiry',
      batch_number: batch.batch_number,
      expiration_date: batch.expiration_date.strftime("%m/%d/%Y"),
      days_remaining: (batch.expiration_date.to_date - Date.current).to_i,
      locations: locations_list,
      product_count: all_items.map(&:product_id).uniq.count
    )
  end

  def send_user_notifications(user, batch, message)
    if user.email_notification
      NotificationMailer.upcoming_expiration_date(
        user: user,
        batch: batch
      ).deliver_now  # changed for rake task debugging
    end

    if user.text_notification && user.phone.present?
      NotificationService.send_sms(
        phone: user.phone,
        message: "Expiration Alert: #{message.truncate(100)}"
      )
    end
  end
end
