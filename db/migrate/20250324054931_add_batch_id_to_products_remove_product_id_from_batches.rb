class AddBatchIdToProductsRemoveProductIdFromBatches < ActiveRecord::Migration[8.0]
  def change
    remove_reference :batches, :product
    add_reference :products, :batch
  end
end
