class Category < ApplicationRecord
  has_many :products, dependent: :nullify
  belongs_to :account
end