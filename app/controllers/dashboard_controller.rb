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

    @current_location = session[:current_location_id] && Current.account.locations.find_by(id: session[:current_location_id]) || Current.account.locations.first
    @recipes = Current.account.recipes
  
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end  

  def switch_location
    locations = Current.account.locations.to_a
    current_index = locations.index { |loc| loc.id == session[:current_location_id] } || 0
    next_location = locations.rotate(current_index + 1).first
    session[:current_location_id] = next_location.id
    redirect_to dashboard_path, status: :see_other
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