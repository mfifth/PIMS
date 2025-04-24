class Recipe < ApplicationRecord
  belongs_to :account
  has_many :recipe_items, dependent: :destroy
  has_many :products, through: :recipe_items

  accepts_nested_attributes_for :recipe_items, allow_destroy: true

  validates :uid, presence: true, uniqueness: true
  validates :name, presence: true

  def max_quantity_and_expiration(location)
    quantities = []
    expirations = []
  
    recipe_items.includes(product: :batch).each do |item|
      inventory_items = location.inventory_items
                                  .includes(product: :batch)
                                  .where(product: item.product)
  
      next if inventory_items.empty?
  
      total_quantity = inventory_items.sum(&:quantity)
      available = total_quantity / item.quantity
      quantities << available.floor
  
      if item.product.perishable?
        soonest_expiration = inventory_items.map { |inv| inv.product.batch&.expiration_date }.compact.min
        expirations << soonest_expiration if soonest_expiration
      end
    end
  
    [quantities.min || 0, expirations.min]
  end     
end
  