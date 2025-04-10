class InventoryItemsController < ApplicationController
  def lookup
    item = InventoryItem.find_by(product_id: params[:product_id], location_id: params[:location_id])

    render json: {
      quantity: item&.quantity,
      low_threshold: item&.low_threshold
    }
  end
end
