class RecipeOrderProcessorService
  def initialize(location)
    @location = location
  end

  def process_recipe(recipe, quantity_sold)
    recipe.recipe_items.each do |recipe_item|
      product = recipe_item.product
      next unless product && recipe_item.quantity.to_f > 0 && quantity_sold.to_f > 0

      inventory_item = @location.inventory_items.find_by(product: product)
      next unless inventory_item

      converted_quantity = if recipe_item.unit == inventory_item.unit_type
                             recipe_item.quantity.to_f
                           else
                             recipe_item.quantity.to_f * conversion_rate(recipe_item.unit, inventory_item.unit_type)
                           end

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
        inventory_item.quantity *= conversion_rate(inventory_item.unit_type, next_unit)
        inventory_item.unit_type = next_unit
  
        Rails.logger.info "Inventory #{inventory_item.product.name} switched to #{next_unit} (quantity: #{inventory_item.quantity})"
      else
        break
      end
    end
  end  

  def conversion_rate(from_unit, to_unit)
    {
      'grams' => {
        'grams' => 1,
        'ounces' => 1.0 / 28.3495,
        'pounds' => 1.0 / 453.592
      },
      'ounces' => {
        'grams' => 28.3495,
        'ounces' => 1,
        'pounds' => 1.0 / 16
      },
      'pounds' => {
        'grams' => 453.592,
        'ounces' => 16,
        'pounds' => 1
      },
      'kilograms' => {
        'grams' => 1000,
        'kilograms' => 1
      },
      'liters' => {
        'liters' => 1,
        'gallons' => 1.0 / 3.78541,
        'fluid_oz' => 33.814,
        'milliliters' => 1000
      },
      'gallons' => {
        'liters' => 3.78541,
        'gallons' => 1,
        'fluid_oz' => 128,
        'milliliters' => 3785.41
      },
      'fluid_oz' => {
        'liters' => 0.0295735,
        'gallons' => 1.0 / 128,
        'fluid_oz' => 1,
        'milliliters' => 29.5735
      },
      'milliliters' => {
        'liters' => 0.001,
        'gallons' => 0.000264172,
        'fluid_oz' => 0.033814,
        'milliliters' => 1
      },
      'units' => {
        'units' => 1
      }
    }.dig(from_unit, to_unit) || 1
  end  
end
