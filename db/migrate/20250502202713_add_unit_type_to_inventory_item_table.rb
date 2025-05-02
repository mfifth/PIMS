class AddUnitTypeToInventoryItemTable < ActiveRecord::Migration[8.0]
  def change
    add_column :inventory_items, :unit_type, :string, default: "units"
  end
end
