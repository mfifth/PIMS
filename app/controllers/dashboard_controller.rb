class DashboardController < ApplicationController
  def index
    load_batches if should_load?('batches')
    load_recipes if should_load?('recipes')
    load_products if should_load?('products')
  
    @low_stock_items = {}
    load_low_stock_items
    
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
                  .includes(:inventory_items)
                  .order(expiration_date: :asc)
                  .page(params[:batches_page]).per(5)
  end

  def load_recipes
    @recipes = Current.account.recipes.includes(:recipe_items).page(params[:recipes_page]).per(5)
  end

  def load_products
    @products = Current.account.products
                  .includes(:inventory_items, :batches)
                  .left_joins(inventory_items: :batch)
                  .select('products.*, MIN(batches.expiration_date) AS earliest_expiration')
                  .group('products.id')
                  .order(Arel.sql('earliest_expiration ASC NULLS LAST, products.id ASC'))
                  .page(params[:products_page]).per(5)
  end

  def load_low_stock_items
    Current.account.locations.includes(inventory_items: [:product, :batch]).find_each do |location|
      low_items = location.inventory_items.select do |item|
        item.quantity < (item.low_threshold || 0)
      end

      @low_stock_items[location.id] = low_items if low_items.any?
    end
  end
end