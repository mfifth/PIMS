class Batch < ApplicationRecord
  has_many :products
  belongs_to :account
  belongs_to :supplier, optional: true

  validates :batch_number, presence: true
  validates :expiration_date, presence: true

  after_save :check_expiration

  def batch_info
    "#{batch_number} - MFG: #{manufactured_date || 'N/A'} | EXP: #{expiration_date || 'N/A'}"
  end

  private

  def check_expiration
    if expiration_date.present? && expiration_date <= Date.today + notification_days_before_expiration.days
      text = "Batch ##{batch_number} with #{products.count} products at is expiring soon (#{expiration_date})"
      message = text + 
        (Current.user.email_notification ? "Email alerts are enabled." : "") +
        (Current.user.text_notification ? "Text alerts are enabled." : "")

      Notification.create(
        message: message,
        notification_type: "Alert"
      )

      return unless Current.user.email_notification
      NotificationMailer.upcoming_expiration_date(Current.user, self).deliver_now

      return unless Current.user.text_notification
      NotificationService.send_sms(Current.user.phone, text)
    end
  end
end
