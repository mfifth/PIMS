class RecipeOrderProcessorService
  def initialize(location)
    @location = location
  end

  def process_recipe(recipe, quantity_sold, excluded_modifiers: [])
    recipe.recipe_items.each do |recipe_item|
      product = recipe_item.product
      next unless product && recipe_item.quantity.to_f > 0 && quantity_sold.to_f > 0
      next if excluded_modifiers.include?(product.id)

      inventory_item = @location.inventory_items.find_by(product: product)
      next unless inventory_item

      converted_quantity = recipe_item.convert_quantity(recipe_item.quantity.to_f, inventory_item.unit_type)
      quantity_to_deduct = converted_quantity * quantity_sold.to_f
      deduct_inventory(inventory_item, quantity_to_deduct)
    end
  end

  private

  def deduct_inventory(inventory_item, quantity_to_deduct)
    new_quantity = inventory_item.quantity - quantity_to_deduct
    inventory_item.quantity = [new_quantity, 0].max

    auto_adjust_unit(inventory_item)

    inventory_item.save!
  end

  def auto_adjust_unit(inventory_item)
    unit_chains = {
      'pounds' => ['pounds', 'ounces', 'grams'],
      'ounces' => ['ounces', 'grams'],
      'kilograms' => ['kilograms', 'grams'],
      'gallons' => ['gallons', 'liters', 'milliliters'],
      'liters' => ['liters', 'milliliters'],
      'fluid_oz' => ['fluid_oz', 'milliliters']
    }

    chain = unit_chains[inventory_item.unit_type]
    return unless chain

    loop do
      current_index = chain.index(inventory_item.unit_type)
      break if current_index.nil?

      if inventory_item.quantity < 1 && current_index + 1 < chain.length
        next_unit = chain[current_index + 1]
        inventory_item.quantity *= RecipeItem::CONVERSION_RATES.dig(inventory_item.unit_type, next_unit) || 1
        inventory_item.unit_type = next_unit

        Rails.logger.info "Inventory #{inventory_item.product.name} switched to #{next_unit} (quantity: #{inventory_item.quantity})"
      else
        break
      end
    end
  end
end
