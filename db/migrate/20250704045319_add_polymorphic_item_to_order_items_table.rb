class AddPolymorphicItemToOrderItemsTable < ActiveRecord::Migration[8.0]
  def change
    rename_column :order_items, :item_id, :item_id_int
    add_column :order_items, :item_id, :integer

    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE order_items SET item_id = item_id_int
        SQL
      end

      dir.down do
        remove_column :order_items, :item_id
        rename_column :order_items, :item_id_int, :item_id
      end
    end

    remove_column :order_items, :item_id_int
    add_index :order_items, [:item_type, :item_id]
  end
end
