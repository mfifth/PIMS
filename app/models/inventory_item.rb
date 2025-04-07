class InventoryItem < ApplicationRecord
  belongs_to :location
  belongs_to :product

  scope :sorted_by_expiration, -> { order(:expiration_date) }
  scope :not_expired, -> { where('expiration_date <= ?', Date.today) }

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  
  after_save :check_low_stock

  private

  def check_low_stock
    return unless low_threshold && quantity <= low_threshold

    text = "#{product.name} is running low at #{location.name} (#{quantity} left). "

    Notification.create(
      message: text,
      notification_type: "Alert",
      account_id: product.account.id
    )

    product.account.users do |user|
      NotificationMailer.low_inventory_alert(self, user).deliver_now if user.email_notification
      NotificationService.send_sms(user.phone, text) if user.text_notification
    end
  end
end
