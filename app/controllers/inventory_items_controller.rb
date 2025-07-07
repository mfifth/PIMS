class InventoryItemsController < ApplicationController
  def lookup
    item = InventoryItem.find_by(product_id: params[:product_id], location_id: params[:location_id])

    render json: {
      quantity: item&.quantity,
      low_threshold: item&.low_threshold,
      unit_type: item&.unit_type,
      price: item&.price,
      batch_id: item&.batch.try(:id)
    }
  end

  def search
    query = params[:query].to_s.strip.downcase
    location_id = params[:location_id]

    inventory_items = InventoryItem.includes(:product, :location)
                                  .where("LOWER(products.name) LIKE ?", "%#{query}%")
                                  .where(location_id: location_id)
                                  .references(:product)

    recipes = Recipe.where("LOWER(name) LIKE ?", "%#{query}%")

    results = []

    results += inventory_items.map do |item|
      {
        id: item.id,
        item_type: "InventoryItem",
        product_name: item.product.name,
        sku: item.product.sku,
        unit_type: item.unit_type,
        quantity: item.quantity,
        price: item.price.to_f,
        location_id: item.location_id,
        location_name: item.location.name,
        conversion_rates: UnitConversion::CONVERSION_RATES[item.unit_type] || {},
        unit_options: UnitConversion.compatible_units_for(item.unit_type).map { |u| { value: u, label: u.humanize } }
      }
    end

    results += recipes.map do |recipe|
      {
        id: recipe.id,
        item_type: "Recipe",
        product_name: recipe.name,
        sku: "RECIPE",
        unit_type: "n/a",
        quantity: 1,
        price: recipe.price.to_f,
        location_id: location_id.to_i,
        location_name: "N/A"
      }
    end

    render json: results
  end


  def destroy
    @inventory_item = InventoryItem.find(params[:id])
    @inventory_item.destroy
  
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@inventory_item) }
    end
  end  
end
