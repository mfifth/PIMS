module DashboardHelper
  def max_quantity_and_expiration(location, recipe)
    return [0, nil] if recipe.recipe_items.empty?

    min_quantity = Float::INFINITY
    earliest_expiration = nil

    recipe.recipe_items.includes(product: [:batch, :inventory_items]).each do |recipe_item|
      product = recipe_item.product
      inventory_items = location.inventory_items.where(product: product)

      return [0, nil] if inventory_items.empty?

      total_available = inventory_items.sum do |inventory_item|
        recipe_item.convert_from_inventory(inventory_item.unit_type, inventory_item.quantity)
      end

      required_quantity = recipe_item.quantity

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
