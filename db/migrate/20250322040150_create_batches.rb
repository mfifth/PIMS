class CreateBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :batches do |t|
      t.references :product, null: false, foreign_key: true
      t.string :batch_number, null: false
      t.date :manufactured_date
      t.date :expiration_date
      t.integer :quantity, default: 0

      t.timestamps
    end
  end
end
