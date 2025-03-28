class DashboardController < ApplicationController
  def index
    @orders = Current.account.orders
    @batches = Current.account.batches.includes(products: :inventory_items)
    @locations = Current.account.locations

    @total_merchandise_value = InventoryItem.where(location_id: @locations.ids)
                                            .joins(:product)
                                            .sum('inventory_items.quantity * products.price')
    
    # Fetch perishable products by checking if they have a batch with a valid expiration date
    @perishables = Product.where(user_id: Current.user.id, user_id: Current.user.id, perishable: true).distinct

    # Non-perishable products: Exclude perishables and filter by user
    @non_perishables = Product.where(user_id: Current.user.id, perishable: false)

    @total_orders = Current.user.orders.count
    @total_suppliers = Current.user.suppliers.count
  end
end
