module DashboardHelper
  def max_quantity_and_expiration(location, recipe)
    min_quantity = Float::INFINITY
    earliest_expiration = nil

    recipe.recipe_items.includes(product: [:batch, :inventory_items]).each do |recipe_item|
      product = recipe_item.product
      inventory_items = location.inventory_items.where(product: product)

      return [0, nil] if inventory_items.empty?

      # Convert required quantity to product's unit_type
      if recipe_item.convertible_units?(recipe_item.unit, product.unit_type)
        required_quantity = recipe_item.converted_quantity(product.unit_type)
      else
        return [0, nil]
      end

      total_available = inventory_items.sum(&:quantity)

      return [0, nil] if required_quantity <= 0 || total_available < required_quantity

      max_recipes_for_item = (total_available / required_quantity).floor
      min_quantity = [min_quantity, max_recipes_for_item].min

      if product.perishable?
        inventory_expirations = product.batch&.expiration_date
        return [0, nil] unless inventory_expirations

        earliest_expiration = [earliest_expiration, inventory_expirations].compact.min
      end
    end

    [min_quantity, earliest_expiration]
  end
end
