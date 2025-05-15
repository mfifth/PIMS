class AddBatchIdToInventoryItemsTable < ActiveRecord::Migration[8.0]
  def change
    add_column :inventory_items, :batch_id, :integer
    add_index :inventory_items, :batch_id
    
    execute <<-SQL
      UPDATE inventory_items
      SET batch_id = products.batch_id
      FROM products
      WHERE inventory_items.product_id = products.id
    SQL
    
    remove_column :products, :batch_id
  end
end
