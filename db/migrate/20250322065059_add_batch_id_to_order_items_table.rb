class AddBatchIdToOrderItemsTable < ActiveRecord::Migration[8.0]
  def change
    add_reference :order_items, :batch
  end
end
