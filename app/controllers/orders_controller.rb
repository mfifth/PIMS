class OrdersController < ApplicationController
  before_action :set_locations, only: [:new, :create]

  def index
    @orders = Current.account.orders.includes(:order_items).order(created_at: :desc)
  end

  def new
    @order = Current.account.orders.new
  end

  def edit
    @order = Current.account.orders.includes(order_items: [:item]).find(params[:id])
    @locations = Current.account.locations
  end

  def update
    @order = Current.account.orders.includes(order_items: [:item]).find(params[:id])

    ActiveRecord::Base.transaction do
      @order.order_items.each do |order_item|
        if order_item.item.is_a?(Recipe)
          RecipeOrderProcessorService.new(@order.location).process_recipe(
            order_item.item,
            -order_item.quantity
          )
        elsif order_item.item.is_a?(InventoryItem)
          order_item.item.update!(
            quantity: order_item.item.quantity + order_item.quantity
          )
        end
      end

      if @order.update(order_params)
        redirect_to @order, notice: "Order updated"
      else
        @locations = Current.account.locations
        raise ActiveRecord::Rollback
      end
    end
  rescue => e
    logger.error "Order update failed: #{e.message}"
    @locations = Current.account.locations
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @order = Current.account.orders.includes(order_items: [:item]).find(params[:id])

    ActiveRecord::Base.transaction do
      @order.order_items.each do |order_item|
        if order_item.item.is_a?(Recipe)
          RecipeOrderProcessorService.new(@order.location).process_recipe(order_item.item, -order_item.quantity)
        elsif order_item.item.is_a?(InventoryItem)
          order_item.item.update!(quantity: order_item.item.quantity + order_item.quantity)
        end
      end

      @order.destroy!
    end

    redirect_to orders_path, notice: "Order deleted and inventory restored"
  rescue => e
    logger.error "Order delete failed: #{e.message}"
    redirect_to orders_path, alert: "Failed to delete order"
  end

  def show
    @order = Current.account.orders.includes(order_items: :item).find(params[:id])
  end

  def create
    @order = Current.account.orders.new(location_id: order_params[:location_id])
    @order.total = 0

    ActiveRecord::Base.transaction do
      grouped_items = order_params[:order_items_attributes].values.group_by do |item|
        [item[:item_type], item[:item_id]]
      end

      grouped_items.each do |(item_type, item_id), items|
        total_quantity = items.sum { |i| i[:quantity].to_i }
        first_item = items.first

        klass = item_type.constantize
        item = klass.find(item_id)
        price = first_item[:price].to_f

        @order.order_items.build(
          item: item,
          location_id: first_item[:location_id],
          quantity: total_quantity,
          price: price
        )

        if item.is_a?(Recipe)
          RecipeOrderProcessorService.new(@order.location).process_recipe(item, total_quantity)
        elsif item.is_a?(InventoryItem)
          item.update!(quantity: item.quantity - total_quantity)
        end

        @order.total += price * total_quantity
      end

      @order.save!
      redirect_to @order, notice: "Order created successfully"
    end
  rescue => e
    logger.error "Order creation failed: #{e.message}"
    @locations = Current.account.locations
    render :new, status: :unprocessable_entity
  end

  private

  def order_params
    params.require(:order).permit(
      :location_id,
      order_items_attributes: [:id, :item_id, :item_type, :quantity, :price, :location_id, :_destroy]
    ).tap do |whitelisted|
      if whitelisted[:order_items_attributes].is_a?(Hash)
        whitelisted[:order_items_attributes] = whitelisted[:order_items_attributes].values
      end
    end
  end

  def set_locations
    @locations = Current.account.locations
  end
end
