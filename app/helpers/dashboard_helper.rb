module DashboardHelper
  def max_quantity_and_expiration(location, recipe)
    quantities = []
    expirations = []
  
    recipe.recipe_items.includes(product: :batch).each do |item|
      product = item.product
  
      # Find all inventory items for this product at the location
      inventory_items = location.inventory_items.where(product: product)
  
      # If the product isn't present in this location's inventory, the recipe can't be made
      return [0, nil] if inventory_items.blank?
  
      total_quantity = inventory_items.sum(&:quantity)
      recipe_quantity = item.converted_quantity(product.unit_type)
  
      return [0, nil] if total_quantity < recipe_quantity
  
      quantities << (total_quantity / recipe_quantity).floor
  
      if product.perishable?
        expiration = product.batch&.expiration_date
        return [0, nil] unless expiration
  
        expirations << expiration
      end
    end
  
    [quantities.min || 0, expirations.min]
  end
end
