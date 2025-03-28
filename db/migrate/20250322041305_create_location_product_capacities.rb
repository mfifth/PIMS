class CreateLocationProductCapacities < ActiveRecord::Migration[7.0]
  def change
    create_table :location_product_capacities do |t|
      t.references :location, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :capacity, null: false, default: 0 # Max capacity for this product type
      t.integer :used_capacity, null: false, default: 0 # Amount of capacity already used for this product

      t.timestamps
    end
  end
end
