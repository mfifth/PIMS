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

  validates :email_address, presence: true, uniqueness: true
  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validate :user_limit_not_exceeded, on: :create

  after_create :create_account_details

  def send_confirmation_email!
    generate_confirmation_token unless confirmation_token?
    save! # Save the token if newly generated
    InvitationMailer.confirmation_instructions(self).deliver_later
  end

  def generate_confirmation_token
    regenerate_confirmation_token
    self.confirmation_sent_at = Time.current
    self.confirmation_token_expires_at = 24.hours.from_now
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
    return if skip_account_creation
    account = Account.create
    account.users << self
    account.save
  end

  def user_limit_not_exceeded
    return unless account
    if account.users.count >= USER_PLAN_LIMITS[account.subscription.plan]
      errors.add(:base, "You have reached the maximum limit of #{USER_PLAN_LIMITS[account.subscription.plan]} users.")
    end
  end
end
