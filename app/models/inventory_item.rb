class InventoryItem < ApplicationRecord
  belongs_to :location
  belongs_to :product
  belongs_to :batch, optional: true
  
  scope :sorted_by_expiration, -> { 
    joins(:batch).order('batches.expiration_date, batches.manufactured_date') 
  }

  scope :not_expired, -> { 
    joins(:batch).where('batches.expiration_date >= ?', Date.today) 
  }
  
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: { scope: [:location_id, :batch_id], message: "already exists in this location with this batch" }
  
  after_save :check_low_stock
  
  def expiration_date
    batch&.expiration_date
  end
  
  def manufactured_date
    batch&.manufactured_date
  end
  
  private

  def check_low_stock
    return unless low_threshold && quantity <= low_threshold

    text = I18n.t('notifications.low_limit_warning', product: product.name, 
    location_name: location.name, quantity: quantity)

    Notification.create(
      message: text,
      notification_type: "alert",
      account_id: product.account.id
    )

    product.account.users do |user|
      NotificationMailer.low_inventory_alert(self, user).deliver_now if user.email_notification
      NotificationService.send_sms(user.phone, text) if user.text_notification
    end
  end
end
