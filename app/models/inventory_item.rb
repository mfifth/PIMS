class InventoryItem < ApplicationRecord
  belongs_to :location
  belongs_to :product

  scope :sorted_by_expiration, -> { order(:expiration_date) }

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  
  after_save :check_low_stock

  private

  def check_low_stock
    if low_threshold && quantity <= low_threshold
      message = "#{product.name} is running low at #{location.name} (#{quantity} left). " +
                 (Current.account.email_notification ? "Email alerts are enabled." : "Email alerts are disabled.") +
                 (Current.account.text_notification ? "Text alerts are enabled." : "Text alerts are disabled.")
      Notification.create(
        message: message,
        notification_type: "Alert"
      )

      return unless Current.account.email_notification
      NotificationMailer.low_inventory_alert(self, Current.user).deliver_now

      return unless Current.account.text_notification
      NotificationService.send_sms(Current.user.phone, message)
    end
  end
end
