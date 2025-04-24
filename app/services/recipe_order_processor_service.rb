class RecipeOrderProcessor
    def initialize(account, location)
      @account = account
      @location = location
    end

    def process_recipe(recipe, quantity_sold)
      recipe.recipe_items.each do |recipe_item|
        product = recipe_item.product
        next unless product&.unit_type

        converted_quantity = if recipe_item.unit == product.unit_type
            recipe_item.quantity
        else
            recipe_item.quantity * conversion_rate(recipe_item.unit, product.unit_type)
        end

        quantity_to_deduct = converted_quantity * quantity_sold
        update_inventory_item(product, -quantity_to_deduct)
      end
    end

    private

    def update_inventory_item(product, quantity_change)
      inventory_item = @location.inventory_items.find_or_initialize_by(product: product)
      inventory_item.quantity += quantity_change
      inventory_item.save!
    end

    def conversion_rate(from_unit, to_unit)
      {
        'grams' => { 'grams' => 1, 'ounces' => 1.0 / 28.3495, 'pounds' => 1.0 / 453.592 },
        'ounces' => { 'grams' => 28.3495, 'ounces' => 1, 'pounds' => 1.0 / 16 },
        'pounds' => { 'grams' => 453.592, 'ounces' => 16, 'pounds' => 1 },
        'liters' => { 'liters' => 1, 'gallons' => 1.0 / 3.78541 },
        'gallons' => { 'liters' => 3.78541, 'gallons' => 1 },
        'units' => { 'units' => 1 }
      }.dig(from_unit, to_unit) || 1
    end
end