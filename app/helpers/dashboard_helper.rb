module DashboardHelper
  def max_quantity_and_expiration(location, recipe)
    quantities = []
    expirations = []
  
    recipe.recipe_items.includes(product: :batch).each do |item|
      inventory_items = location.inventory_items
                                 .includes(product: :batch)
                                 .where(product: item.product)
  
      next if inventory_items.empty?
  
      target_unit = item.product.unit_type
      recipe_quantity = item.converted_quantity(target_unit)
  
      total_quantity = inventory_items.sum(&:quantity)
      available = total_quantity / recipe_quantity
      quantities << available.floor
  
      if item.product.perishable?
        soonest_expiration = inventory_items.map { |inv| inv.product.batch&.expiration_date }.compact.min
        expirations << soonest_expiration if soonest_expiration
      end
    end
  
    [quantities.min || 0, expirations.min]
  end
end
