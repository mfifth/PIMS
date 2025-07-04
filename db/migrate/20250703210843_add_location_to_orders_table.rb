class AddLocationToOrdersTable < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :location_id, :integer
  end
end
