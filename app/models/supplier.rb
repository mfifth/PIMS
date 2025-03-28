class Supplier < ApplicationRecord
  has_many :products, dependent: :destroy
  belongs_to :account

  validates :name, presence: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone_number, presence: true
end