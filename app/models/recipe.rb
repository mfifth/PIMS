class Recipe < ApplicationRecord
  belongs_to :account
  has_many :recipe_items, dependent: :destroy
  has_many :products, through: :recipe_items

  accepts_nested_attributes_for :recipe_items, allow_destroy: true

  validates :uid, presence: true, uniqueness: { scope: :account_id }
  validates :name, presence: true, uniqueness: { scope: :account_id }
end
  