class AddUnitTypesToProductsTable < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :unit_type, :string, default: "unit"
  end
end
