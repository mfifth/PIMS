class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]
  before_action :require_admin!, only: [:create, :update, :destroy, :edit]

  def index
    @products = Current.account.products
                               .left_joins(:category)
                               .includes(inventory_items: :location)
                               .joins(inventory_items: :location)
  
    if params[:query].present?
      query = "%#{params[:query]}%"
      adapter = ActiveRecord::Base.connection.adapter_name.downcase
  
      like_operator = adapter.include?("postgresql") ? "ILIKE" : "LIKE"
  
      @products = @products.where(
        "products.name #{like_operator} :q OR products.sku #{like_operator} :q 
        OR categories.name #{like_operator} :q OR locations.name #{like_operator} :q",
        q: query
      )
    else
      @products = @products.order("products.name ASC")
    end
  
    @products = @products.page(params[:page]).per(5)
  
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end  

  def show
    @batches = @product.batches.distinct
    @inventory_items = @product.inventory_items.includes(:batch, :location)
    @locations = Location.joins(:inventory_items)
                         .where(inventory_items: { product_id: @product.id })
                         .distinct

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @product = Product.new

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @product = Product.new(product_params.merge(account_id: Current.account.id))

    if @product.save
      assign_or_create_category
      create_inventory_item if inventory_item_params.present?
      redirect_to @product, notice: 'Product was successfully created.'
    else
      render :new
    end
  end

  def update
    if @product.update(product_params)
      assign_or_create_category
      update_inventory_item if update_inventory?
      redirect_to @product, notice: 'Product was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @product.destroy
  
    respond_to do |format|
      format.html { redirect_to products_path, notice: t('notifications.product_deleted') }
      format.turbo_stream
    end
  end

  def remove_category
    @product.update(category_id: nil)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to edit_product_path(@product), notice: t('notifications.category_removed') }
    end
  end

  def delete_category
    @product.category.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to edit_product_path(@product), notice: t('notifications.category_deleted') }
    end
  end

  def remove_batch
    @product = Product.find(params[:id])
    @batch = Batch.find(params[:batch_id])
    
    @product.inventory_items.where(batch_id: @batch.id).each do |inventory_item| 
      inventory_item.update!(batch_id: nil) 
    end
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("batch_#{@batch.id}")
      end
      format.html { redirect_to edit_product_path(@product), notice: 'Batch was successfully removed' }
    end
  end

  private

  def set_product
    @product = Product.includes(:inventory_items, :batches).find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name, :sku, :unit_type, :category_name, :category_id, 
      :description, :perishable, :supplier_id, 
      :user_id, :account_id
    )
  end

  def inventory_item_params
    params.require(:product).permit(
      :quantity, :location_id, :unit_type, 
      :daily_usage, :low_threshold, :price,
      :batch_number, :manufactured_date,
      :expiration_date, :notification_days_before_expiration
    )
  end

  def update_inventory?
    inventory_item_params[:location_id] && inventory_item_params[:quantity]
  end

  def update_inventory_item
    inventory_item = InventoryItem.find_or_initialize_by(
      location_id: inventory_item_params[:location_id],
      product_id: @product.id
    )

    if params[:product][:selected_batch_id].present?
      inventory_item.update(batch_id: params[:product][:selected_batch_id])
    elsif inventory_item_params[:batch_number] && inventory_item_params[:expiration_date].present?
      batch = Batch.find_or_initialize_by(
        account_id: Current.account.id,
        batch_number: inventory_item_params[:batch_number]
      )

      batch.update!(
        manufactured_date: inventory_item_params[:manufactured_date],
        expiration_date: inventory_item_params[:expiration_date],
        notification_days_before_expiration: inventory_item_params[:notification_days_before_expiration]
      )
      
      inventory_item.update(batch_id: batch.id)
    end

    inventory_item.update!(
      quantity: inventory_item_params[:quantity],
      unit_type: inventory_item_params[:unit_type],
      low_threshold: inventory_item_params[:low_threshold],
      price: inventory_item_params[:price]
    )

    Location.find(inventory_item_params[:location_id]).update(updated_at: Time.current)
  end

  def assign_or_create_category
    if product_params[:category_name].present? 
      category = Current.account.categories.find_or_create_by(name: product_params[:category_name].downcase)
      @product.update(category: category)
    elsif product_params[:category_id].present?
      category = Category.find(product_params[:category_id])
      @product.update(category: category)
    end
  end

  def create_inventory_item
    inventory_item = InventoryItem.new(
      product: @product,
      location_id: inventory_item_params[:location_id],
      quantity: inventory_item_params[:quantity],
      unit_type: inventory_item_params[:unit_type],
      daily_usage: inventory_item_params[:daily_usage],
      low_threshold: inventory_item_params[:low_threshold],
      price: inventory_item_params[:price]
    )

    if @product.perishable? && inventory_item_params[:batch_number].present?
      batch = Batch.create!(
        account_id: Current.account.id,
        batch_number: inventory_item_params[:batch_number],
        manufactured_date: inventory_item_params[:manufactured_date],
        expiration_date: inventory_item_params[:expiration_date],
        notification_days_before_expiration: inventory_item_params[:notification_days_before_expiration]
      )
      inventory_item.batch = batch
    end

    inventory_item.save!
    Location.find(inventory_item_params[:location_id]).update(updated_at: Time.current)
  end
end