class DropTableForInventories < ActiveRecord::Migration[8.0]
  def change
    drop_table :inventories
  end
end
