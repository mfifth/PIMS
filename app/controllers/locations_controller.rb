class LocationsController < ApplicationController
  before_action :set_location, only: %i[show edit update destroy]

  def index
    @locations = Current.account.locations.includes(:inventory_items)
  end

  def show
    @inventory_items = @location.inventory_items
                  .includes(product: [:category, :batch])
                  .order('products.name ASC')

    if params[:perishable].present?
      @inventory_items = @inventory_items.where(products: { perishable: params[:perishable] == 'true' })
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end 
  end

  def new
    @location = Location.new
  end

  def create
    @location = Location.new(location_params.merge(account_id: Current.account.id))
    if @location.save
      redirect_to @location, notice: 'Location was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream
    end 
  end

  def update
    if @location.update(location_params)
      redirect_to @location, notice: 'Location was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @location.destroy
    redirect_to locations_path, notice: 'Location was successfully deleted.'
  end

  def inventory
  end

  def update_inventory
    Product.find(params[:product_id]).update(batch_id: params[:batch_id])
    InventoryItem.find_by(location_id: params[:location_id], product_id: params[:product_id])
    .update(quantity: params[:quantity])

    redirect_back fallback_location: '/', notice: "Inventory updated successfully."
  end

  # In your LocationsController
  def inventory_data
    location = Location.find(params[:location_id])
    products = location.products
                       .includes(:batch, :inventory_items)
                       .where(inventory_items: { location_id: location.id })
                       .references(:inventory_items)
  
    render json: {
      products: products.map do |product|
        inventory_item = product.inventory_items.find_by(location_id: location.id)
        {
          id: product.id,
          name: product.name,
          quantity: inventory_item&.quantity || 0,
          batch_id: product.batch_id
        }
      end
    }
  end

  private

  def set_location
    @location = Location.find(params[:id])
  end

  def location_params
    params.require(:location).permit(:name, :address, :city, :state, :zip_code, :country)
  end
end
