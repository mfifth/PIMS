class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :sku, null: false
      t.string :category, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0.0
      t.boolean :perishable, default: false
      t.references :supplier, foreign_key: true

      t.timestamps
    end
  end
end
