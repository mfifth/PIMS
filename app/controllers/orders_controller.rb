class OrdersController < ApplicationController
  before_action :set_locations, only: [:new, :create, :edit, :update]

  def index
    @orders = Current.account.orders.includes(:order_items).order(created_at: :desc)
  end

  def new
    @order = Current.account.orders.new
  end

  def edit
    @order = Current.account.orders.includes(order_items: [:item]).find(params[:id])
  end

  def show
    @order = Current.account.orders.includes(order_items: :item).find(params[:id])
  end

  def create
    @order = Current.account.orders.new(location_id: order_params[:location_id])
    @order.total = 0

    ActiveRecord::Base.transaction do
      grouped_items = order_params[:order_items_attributes].group_by { |i| [i[:item_type], i[:item_id], i[:unit]] }

      grouped_items.each do |(item_type, item_id, unit), items|
        total_quantity = items.sum { |i| i[:quantity].to_f }
        first_item = items.first

        klass = item_type.constantize
        item = klass.find(item_id)
        price = first_item[:price].to_f

        order_item = @order.order_items.build(
          item: item,
          location_id: first_item[:location_id],
          quantity: total_quantity,
          unit: unit,
          price: price
        )

        OrderItemProcessorService.new(@order.location).process(order_item: order_item, action: :add)
        @order.total += order_item.total_price
      end

      @order.save!
      redirect_to @order, notice: "Order created successfully"
    end
  rescue => e
    logger.error "Order creation failed: #{e.message}"
    @locations = Current.account.locations
    render :new, status: :unprocessable_entity
  end

  def update
    @order = Current.account.orders.includes(order_items: [:item]).find(params[:id])

    ActiveRecord::Base.transaction do
      # Restore inventory from existing items
      @order.order_items.each do |order_item|
        OrderItemProcessorService.new(@order.location).process(order_item: order_item, action: :remove)
      end

      @order.order_items.destroy_all
      total = 0
      items_attributes = order_params[:order_items_attributes] || []

      # Create a hash to accumulate quantities for identical items
      items_hash = {}
      items_attributes.each do |item_attrs|
        key = [item_attrs[:item_type], item_attrs[:item_id], item_attrs[:unit]].join('-')
        if items_hash[key]
          # Accumulate quantity for identical items
          items_hash[key][:quantity] += item_attrs[:quantity].to_f
        else
          # Store the first occurrence
          items_hash[key] = item_attrs.merge(quantity: item_attrs[:quantity].to_f)
        end
      end

      # Process each unique item
      items_hash.each_value do |item_attrs|
        klass = item_attrs[:item_type].constantize
        item = klass.find(item_attrs[:item_id])

        order_item = @order.order_items.build(
          item: item,
          location_id: item_attrs[:location_id],
          quantity: item_attrs[:quantity],
          unit: item_attrs[:unit],
          price: item_attrs[:price].to_f
        )

        OrderItemProcessorService.new(@order.location).process(order_item: order_item, action: :add)
        total += order_item.total_price
      end

      @order.total = total
      @order.save!

      redirect_to @order, notice: "Order updated"
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
        OrderItemProcessorService.new(@order.location).process(order_item: order_item, action: :remove)
      end

      @order.destroy!
    end

    redirect_to orders_path, notice: "Order deleted and inventory restored"
  rescue => e
    logger.error "Order delete failed: #{e.message}"
    redirect_to orders_path, alert: "Failed to delete order"
  end

  private

  def order_params
    permitted = params.require(:order).permit(
      :location_id,
      order_items_attributes: [:id, :item_id, :item_type, :quantity, :price, :unit, :location_id, :_destroy]
    )

    # Convert to array of hashes
    if permitted[:order_items_attributes].is_a?(ActionController::Parameters)
      permitted[:order_items_attributes] = permitted[:order_items_attributes].to_unsafe_h.values
    elsif permitted[:order_items_attributes].is_a?(Hash)
      permitted[:order_items_attributes] = permitted[:order_items_attributes].values
    end

    # Filter out any destroyed items and ensure we have an array
    permitted[:order_items_attributes] = Array(permitted[:order_items_attributes]).reject { |i| i[:_destroy] == "1" }
    
    permitted
  end

  def set_locations
    @locations = Current.account.locations
  end
end
