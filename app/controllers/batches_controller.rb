class BatchesController < ApplicationController
  before_action :set_batch, only: [:show, :edit, :update, :destroy]
  before_action :require_admin!, only: [:create, :update, :destroy, :edit, :new]

  def index
    @batches = Current.account.batches.search(params[:query])
    @batches = @batches.order(expiration_date: :asc) if params[:query].blank?
    @batches = @batches.page(params[:page]).per(5)
  
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end  

  def show
    @inventory_items = @batch.inventory_items.includes(:product, :location)
  end

  def new
    @batch = Batch.new
    load_dependencies
  end
  
  def edit
    load_dependencies
    @selected_inventory_items = @batch.inventory_items.pluck(:id)
  end

  def create
    @batch = Batch.new(batch_params.merge(account_id: Current.account.id))
    
    if @batch.save
      update_inventory_items
      redirect_to @batch, notice: t('notifications.batch_created')
    else
      load_dependencies
      @products = Current.account.products.perishable
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @batch.update(batch_params)
      update_inventory_items
      redirect_to @batch, notice: t('notifications.batch_updated')
    else
      load_dependencies
      @products = Current.account.products.perishable
      @selected_inventory_items = @batch.inventory_items.pluck(:id)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @batch.inventory_items.update_all(batch_id: nil)
    @batch.destroy

    respond_to do |format|
      format.html { redirect_to batches_url, notice: t('notifications.batch_deleted') }
      format.turbo_stream { render turbo_stream: turbo_stream.remove("batch_#{@batch.id}") }
    end
  end

  def search
    query = params[:query].to_s.strip
    batch = Batch.find_by(id: params[:batch_id])
  
    adapter = ActiveRecord::Base.connection.adapter_name.downcase
    like_op = adapter.include?("sqlite") ? "LIKE" : "ILIKE"
    pattern = "%#{query}%"
  
    inventory_items = InventoryItem
      .joins(:product, :location)
      .where(products: { account_id: Current.account.id })
      .where("products.name #{like_op} :q OR locations.name #{like_op} :q", q: pattern)
  
    inventory_items = inventory_items.where.not(id: batch.inventory_item_ids) if batch
  
    results = inventory_items.limit(5).map do |item|
      {
        id:            item.id,
        product_name:  item.product.name,
        sku:            item.product.sku,
        unit_type:     item.unit_type,
        location_name: item.location.name,
        quantity:      item.quantity
      }
    end
  
    render json: results
  end  

  private

  def set_batch
    @batch = Batch.includes(:account, inventory_items: [:product, :location]).find(params[:id])
  end

  def batch_params
    params.require(:batch).permit(
      :batch_number, 
      :manufactured_date, 
      :notification_days_before_expiration, 
      :expiration_date, 
      :supplier_id,
      inventory_item_ids: []
    )
  end

  def load_dependencies
    @locations = Current.account.locations
    @selected_location = Location.find_by(id: params[:location_id])
    @products = Current.account.products
    @selected_inventory_items = @batch.inventory_item_ids if @batch.persisted?
  end

  def update_inventory_items
    InventoryItem.where(batch_id: @batch.id).update_all(batch_id: nil) if @batch.persisted?
    
    if params[:batch][:inventory_item_ids].present?
      InventoryItem.where(id: params[:batch][:inventory_item_ids]).update_all(batch_id: @batch.id)
    end
  end
end
