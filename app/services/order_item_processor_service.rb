class OrderItemProcessorService
  def initialize(location)
    @location = location
  end

  def process(order_item:, action:)
    item = order_item.item
    quantity = order_item.quantity.to_f
    unit = order_item.unit

    case item
    when Recipe
      process_recipe(item, quantity, action)
    when InventoryItem
      process_inventory_item(item, quantity, unit, action)
    end
  end

  private

  def process_recipe(recipe, quantity, action)
    multiplier = action == :add ? 1 : -1
    RecipeOrderProcessorService.new(@location).process_recipe(recipe, multiplier * quantity)
  end

  def process_inventory_item(item, quantity, unit, action)
    base_unit = item.unit_type

    compatible_units = UnitConversion.unit_compatibility_map[base_unit] || [base_unit]
    return unless compatible_units.include?(unit)

    # Convert quantity from given unit to base unit
    converted_quantity = UnitConversion.convert_quantity(quantity, unit, base_unit)
    # Round quantity according to unit precision
    rounded_quantity = UnitConversion.round_for_unit(converted_quantity, base_unit)

    case action
    when :add
      new_quantity = [item.quantity - rounded_quantity, 0].max
      item.update!(quantity: new_quantity)
    when :remove
      item.update!(quantity: item.quantity + rounded_quantity)
    end
  end
end
