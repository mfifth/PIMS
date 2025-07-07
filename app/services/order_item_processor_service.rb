class OrderItemProcessorService
  def initialize(location)
    @location = location
  end

  def process(order_item:, action:)
    item = order_item.item
    quantity = order_item.quantity
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
    return unless UnitConversion.compatible_units_for(unit).include?(base_unit)

    converted_quantity = UnitConversion.convert(quantity, from: unit, to: base_unit)
    converted_quantity = UnitConversion.rounded(converted_quantity, base_unit)

    case action
    when :add
      item.update!(quantity: [item.quantity - converted_quantity, 0].max)
    when :remove
      item.update!(quantity: item.quantity + converted_quantity)
    end
  end
end
