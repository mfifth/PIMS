class DashboardController < ApplicationController
  def index
    load_batches if should_load?('batches')
    load_locations if should_load?('locations')
    load_products if should_load?('products')
  
    @low_stock_items = {}
  
    Current.account.locations.includes(inventory_items: :product).find_each do |location|
      low_items = location.inventory_items.select do |item|
        item.quantity < (item.low_threshold || 0)
      end
  
      @low_stock_items[location.id] = low_items if low_items.any?
    end
  
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end  

  private

  def should_load?(card_type)
    params[:card].blank? || params[:card] == card_type
  end

  def load_batches
    @batches = Current.account.batches
                      .includes(products: :inventory_items)
                      .order(created_at: :desc)
                      .page(params[:page]).per(5)
  end

  def load_locations
    @locations = Current.account.locations
                        .includes(
                          :inventory_items,
                          products: :batch
                        )
                        .order(created_at: :desc)
                        .page(params[:page]).per(5)
  end

  def load_products
    @products = Current.account.products
                          .includes(
                            :batch,
                            locations: :inventory_items
                          )
                          .distinct
                          .order(created_at: :desc)
                          .page(params[:page]).per(5)
  end
end