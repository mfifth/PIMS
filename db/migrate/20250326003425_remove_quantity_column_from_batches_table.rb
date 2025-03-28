class RemoveQuantityColumnFromBatchesTable < ActiveRecord::Migration[8.0]
  def change
    remove_column :batches, :quantity
  end
end
