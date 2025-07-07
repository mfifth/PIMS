class AddUnitToOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_column :order_items, :unit, :string
  end
end
