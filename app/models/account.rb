class Account < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :locations, dependent: :destroy
  has_many :inventory_items, through: :locations
  has_many :suppliers, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :batches, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_one :subscription, dependent: :destroy

  encrypts :square_access_token, :square_refresh_token
end
