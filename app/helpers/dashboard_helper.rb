module DashboardHelper
  def max_quantity_and_expiration(location, recipe)
    return [0, nil] if recipe.recipe_items.empty?

    min_quantity = Float::INFINITY
    earliest_expiration = nil

    recipe.recipe_items.each do |recipe_item|
      max_for_item = recipe_item.max_possible_quantity(location)
      return [0, nil] if max_for_item.zero?
      
      min_quantity = [min_quantity, max_for_item].min

      if recipe_item.product.perishable?
        item_expiration = recipe_item.earliest_expiration(location)
        earliest_expiration = [earliest_expiration, item_expiration].compact.min
      end
    end

    [min_quantity, earliest_expiration]
  end
end