class AddSupplierIdToBatchesTable < ActiveRecord::Migration[8.0]
  def change
    add_reference :batches, :supplier, null: true, foreign_key: true
  end
end
