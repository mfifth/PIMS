class RecipeOrderProcessor
  def initialize(location)
    @location = location
  end

  def process_recipe(recipe, quantity_sold)
    recipe.recipe_items.each do |recipe_item|
      product = recipe_item.product
      next unless product&.unit_type && recipe_item.quantity.to_f > 0 && quantity_sold.to_f > 0

      converted_quantity = if recipe_item.unit == product.unit_type
        recipe_item.quantity.to_f
      else
        recipe_item.quantity.to_f * conversion_rate(recipe_item.unit, product.unit_type)
      end

      quantity_to_deduct = converted_quantity * quantity_sold.to_f
      deduct_inventory(product, -quantity_to_deduct)
    end
  end

  private

  def deduct_inventory(product, quantity_to_deduct)
    inventory_item = @location.inventory_items.find_by(product: product)
    return unless inventory_item
  
    new_quantity = inventory_item.quantity - quantity_to_deduct
    inventory_item.quantity = [new_quantity, 0].max
    inventory_item.save!
  end
  
  def conversion_rate(from_unit, to_unit)
    {
      'grams' =>   { 'grams' => 1, 'ounces' => 1.0 / 28.3495, 'pounds' => 1.0 / 453.592 },
      'ounces' =>  { 'grams' => 28.3495, 'ounces' => 1, 'pounds' => 1.0 / 16 },
      'pounds' =>  { 'grams' => 453.592, 'ounces' => 16, 'pounds' => 1 },
      'liters' =>  { 'liters' => 1, 'gallons' => 1.0 / 3.78541 },
      'gallons' => { 'liters' => 3.78541, 'gallons' => 1 },
      'units' =>   { 'units' => 1 }
    }.dig(from_unit, to_unit) || 1
  end
end