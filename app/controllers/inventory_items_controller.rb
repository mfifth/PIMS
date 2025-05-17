class InventoryItemsController < ApplicationController
  def lookup
    item = InventoryItem.find_by(product_id: params[:product_id], location_id: params[:location_id])

    render json: {
      quantity: item&.quantity,
      low_threshold: item&.low_threshold,
      unit_type: item&.unit_type,
      price: item&.price
    }
  end

  def destroy
    @inventory_item = InventoryItem.find(params[:id])
    @inventory_item.destroy
  
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@inventory_item) }
    end
  end  
end
