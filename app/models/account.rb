class Account < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :orders, dependent: :destroy
  has_many :locations, dependent: :destroy
  has_many :suppliers, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :batches, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :categories, dependent: :destroy
end
