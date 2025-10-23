class User < ApplicationRecord
  has_secure_token :confirmation_token
  attr_accessor :skip_account_creation

  has_secure_password

  has_many :orders
  has_many :suppliers
  has_many :locations
  has_many :products

  belongs_to :account, optional: true

  has_many :sessions, dependent: :destroy

  validates :accepted_terms, acceptance: true
  validates :email_address, 
  presence: { message: I18n.t('notifications.blank_email') },
  uniqueness: { 
    case_sensitive: false,
    message: I18n.t('notifications.user_already_registered')
  },
  format: {
    with: URI::MailTo::EMAIL_REGEXP,
    message: I18n.t('notifications.email_warning')
  }
  
  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validate :user_limit_not_exceeded, on: :create

  after_create :create_account_details

  def send_confirmation_email!
    generate_confirmation_token
    self.confirmation_sent_at = Time.current
    self.confirmation_token_expires_at = 24.hours.from_now

    save! # Save the token if newly generated
    InvitationMailer.confirmation_instructions(self).deliver_now
  end

  def generate_confirmation_token
    regenerate_confirmation_token unless confirmation_token.present? && confirmation_token_valid?
  end

  def confirmation_token_valid?
    confirmation_token_expires_at.present? && confirmation_token_expires_at > Time.current
  end
  
  # Check if user is confirmed
  def confirmed?
    confirmed_at.present?
  end
  
  # Mark as confirmed
  def confirm!
    update_columns(
      confirmed_at: Time.current,
      confirmation_token: nil,
      confirmation_token_expires_at: nil,
      admin: true
    )
  end

  private

  def create_account_details
    account = Account.create!(
      stripe_customer_id: SecureRandom.hex(8),
      created_at: Time.current,
      updated_at: Time.current
    )

    self.account = account

    subscription = Subscription.create(account_id: account.id)

    Notification.create(message: I18n.t('notifications.basic_instructions'), 
    notification_type: "notice", account_id: account.id)
  end

  def user_limit_not_exceeded
    return unless account

    current_limit = account.subscription.total_user_limit
    if account.users.count >= current_limit
      errors.add(:base, t('notifications.user_limit', limit: current_limit))
    end
  end
end
