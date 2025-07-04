class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.decimal :total, precision: 10, scale: 2, default: "0.0", null: false
      t.references :account
      t.timestamps
    end
  end
end
