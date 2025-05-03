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

    @recipes = Current.account.recipes.includes(:recipe_items)
  
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
                  .order(expiration_date: :asc)
                  .page(params[:batches_page]).per(5)
  end

  def load_locations
    @locations = Current.account.locations
                    .includes(:inventory_items, products: :batch)
                    .order(created_at: :desc)
                    .page(params[:locations_page]).per(5)
  end

  def load_products
    @products = Current.account.products
      .left_joins(:batch)
      .includes(:batch)
      .preload(locations: :inventory_items)
      .select('products.*, batches.expiration_date AS earliest_expiration')
      .order(Arel.sql('earliest_expiration ASC NULLS LAST'))
      .page(params[:products_page]).per(5)
  end
end