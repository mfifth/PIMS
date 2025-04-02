class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]

  def index
    if params[:query].present?
      @products = Current.account.products
      .joins(:category)
      .where("products.name LIKE ? OR products.sku LIKE ? OR categories.name LIKE ?", 
             "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%")
             .page(params[:page]).per(3)
    else
      @products = Current.account.products.page(params[:page]).per(3)
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /products/:id
  def show
    @batches = Batch.where(id: @product.batch_id) # Fetch the associated batch
    @inventory_items = InventoryItem.where(product_id: @product.id)
    @locations = Location.includes(:inventory_items).where(inventory_items: { product_id: @product.id })
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/:id/edit
  def edit
  end

  # POST /products
  def create
    category = create_category if product_params[:category_name].present?
    @product = Product.new(product_params.merge(account_id: Current.account.id, 
    category_id: category&.id || product_params[:category_id]))

    if @product.perishable?
      assign_or_create_batch
    end

    if @product.save
      create_inventory_item if inventory_item_params.present?
      redirect_to @product, notice: 'Product was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /products/:id
  def update
    if @product.update(product_params)
      update_inventory_item if update_inventory?
      assign_or_create_batch if @product.perishable?
      redirect_to @product, notice: 'Product was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /products/:id
  def destroy
    if @product.destroy
      redirect_to products_url, notice: 'Product was successfully destroyed.'
    else
      redirect_to products_url, alert: 'There was an issue deleting the product.'
    end
  end

  private

  def set_product
    @product = Product.includes(:batch).find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :sku, :category_name, :category_id, :description, :price, :perishable, :supplier_id, :user_id, :account_id, :batch_id)
  end

  def batch_params
    params.require(:product).permit(:batch_number, :manufactured_date, :expiration_date) if params[:product][:perishable] == '1'
  end

  def inventory_item_params
    params.require(:product).permit(:quantity, :location_id, :daily_usage, :low_threshold)
  end

  def update_inventory?
    inventory_item_params[:location_id] && inventory_item_params[:quantity]
  end

  def update_inventory_item
    InventoryItem.find_by(location_id: inventory_item_params[:location_id], product_id: @product.id)
                 .update!(inventory_item_params)
  end

  def assign_or_create_batch
    if params[:product][:batch_id].present?
      @product.batch_id = params[:product][:batch_id]
    else
      batch = Batch.create!(batch_params.merge(account_id: Current.account.id, 
      notification_days_before_expiration: params[:product][:notification_days_before_expiration]))
      @product.batch = batch
      @product.save
    end
  end

  def create_category
    Current.account.categories.find_or_create_by(name: product_params[:category_name].downcase)
  end

  def create_inventory_item
    InventoryItem.find_or_create_by!(
      location_id: inventory_item_params[:location_id],
      low_threshold: params[:product][:low_threshold],
      product_id: @product.id,
      quantity: inventory_item_params[:quantity],
      daily_usage: inventory_item_params[:daily_usage]
      )
  end
end
