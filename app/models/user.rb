class User < ApplicationRecord
  has_secure_password
  has_many :orders
  has_many :suppliers
  has_many :locations
  has_many :products

  belongs_to :account, optional: true

  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  after_create :create_account

  def create_account
    #If the user is being added as a non admin role don't create account.
    account = Account.create
    account.users << self
    account.save
  end
end
