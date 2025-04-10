class DashboardController < ApplicationController
  def index
    @batches = Current.account.batches.includes(products: :inventory_items).not_expired.limit(5)
    @locations = Current.account.locations.includes(:inventory_items, products: :batch)
                                            
    # Fetch perishable products by checking if they have a batch with a valid expiration date
    @perishables = Product.where(account_id: Current.account.id, perishable: true).includes(:batch, locations: :inventory_items).distinct

    # Non-perishable products: Exclude perishables and filter by user
    @non_perishables = Product.where(account_id: Current.account.id, perishable: false)
  end
end
