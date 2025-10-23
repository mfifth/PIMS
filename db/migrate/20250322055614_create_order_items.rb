class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      # The orders table is created in a later migration. Creating the
      # foreign key here causes Postgres to raise an error during a fresh
      # deploy, so we add the column now and the foreign key constraint in a
      # subsequent migration once the orders table exists.
      t.references :order, null: false, foreign_key: false
      t.references :product, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true

      t.integer :quantity
      t.decimal :price, precision: 10, scale: 2
      t.timestamps
    end
  end
end