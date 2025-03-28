class AddBatchesToAccountsTable < ActiveRecord::Migration[8.0]
  def change
    add_reference :batches, :account
  end
end
