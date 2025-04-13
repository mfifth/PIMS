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

  validates :email_address, 
  presence: { message: "Email can't be blank" },
  uniqueness: { 
    case_sensitive: false,
    message: 'is already registered. Please sign in or try forgot password.'
  },
  format: {
    with: URI::MailTo::EMAIL_REGEXP,
    message: 'Please enter a valid email address'
  }
  
  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validate :user_limit_not_exceeded, on: :create

  after_create :create_account_details

  def send_confirmation_email!
    generate_confirmation_token unless confirmation_token?
    self.confirmation_sent_at = Time.current
    self.confirmation_token_expires_at = 24.hours.from_now

    save! # Save the token if newly generated
    InvitationMailer.confirmation_instructions(self).deliver_now
  end

  def generate_confirmation_token
    regenerate_confirmation_token
    confirmation_token
  end

  def confirmation_token_valid?
    confirmation_token_expires_at > Time.current
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
      confirmation_token_expires_at: nil
    )
  end

  private

  def create_account_details
    return if Invitation.find_by(email: email_address).present?

    account = Account.create
    account.users << self
    account.save

    Subscription.create(account_id: account.id)
    Notification.create(message: 'Congratulations on settings up your account! 
    Make sure your email and phone are correct so you can get notifications directly to you.', 
    notification_type: "notice", account_id: account.id)
  end

  def user_limit_not_exceeded
    return unless account
    if account.users.count >= USER_PLAN_LIMITS[account.subscription.plan]
      errors.add(:base, "You have reached the maximum limit of #{USER_PLAN_LIMITS[account.subscription.plan]} users.")
    end
  end
end
