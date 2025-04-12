class User < ApplicationRecord
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

  private

  def create_account_details
    return if skip_account_creation
    account = Account.create
    account.users << self
    account.save
  end

  def user_limit_not_exceeded
    if account.users.count >= USER_PLAN_LIMITS[account.subscription.plan]
      errors.add(:base, "You have reached the maximum limit of #{USER_PLAN_LIMITS[account.subscription.plan]} users.")
    end
  end
end
