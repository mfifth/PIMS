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
    @order = Current.account.orders.find(params[:id])

    if @order.update(order_params)
      redirect_to @order, notice: "Order updated"
    else
      @locations = Current.account.locations
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order = Current.account.orders.find(params[:id])
    @order.destroy
    redirect_to orders_path, notice: "Order deleted"
  end

  def show
    @order = Current.account.orders.includes(order_items: :item).find(params[:id])
  end

  def create
    @order = Current.account.orders.new(order_params)
    @order.total = 0

    ActiveRecord::Base.transaction do
      @order.save!

      params[:order][:order_items_attributes].each do |item_params|
        klass = item_params[:item_type].constantize
        item = klass.find(item_params[:item_id])
        quantity = item_params[:quantity].to_i
        price = item_params[:price].to_f

        @order.order_items.create!(
          item: item,
          location_id: item_params[:location_id],
          quantity: quantity,
          price: price
        )

        if item.is_a?(Recipe)
          RecipeOrderProcessorService.new(@order.location).process_recipe(item, quantity)
        elsif item.is_a?(InventoryItem)
          item.update!(quantity: item.quantity - quantity)
        end

        @order.total += price * quantity
      end

      @order.save!
    end

    redirect_to @order, notice: "Order created successfully"
  rescue => e
    logger.error "Order creation failed: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  private

  def order_params
    params.require(:order).permit(
      :location_id,
      order_items_attributes: [:item_id, :item_type, :quantity, :price, :location_id]
    )
  end

  def set_locations
    @locations = Current.account.locations
  end
end
