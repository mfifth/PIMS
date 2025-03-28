class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true

      t.text :order_memo
      t.string :status, default: 'Pending'
      t.decimal :total_amount, precision: 10, scale: 2
      t.boolean :recurring, default: false
      t.date :arrival_date
      t.timestamps
    end
  end
end
