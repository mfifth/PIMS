module DashboardHelper

  def orders_pending(supplier, user)
    @orders_count ||= Order.where(supplier_id: supplier.id, user_id: user.id, status: "Pending").count
    "#{@orders_count} orders pending"
  end

  def orders_in_transit(supplier, user)
    @orders_count ||= Order.where(supplier_id: supplier.id, user_id: user.id, status: "Transit").count
    "#{@orders_count} orders in transit"
  end
  
  def orders_completed
    @orders_count ||= Order.where(supplier_id: supplier.id, user_id: user.id, status: "Completed").count
    "#{@orders_count} orders completed"
  end
end
