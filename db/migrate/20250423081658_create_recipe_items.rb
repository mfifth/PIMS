class CreateRecipeItems < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_items do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2, null: false, default: 1.0
      t.string :unit, null: false, default: "unit"

      t.timestamps
    end

    add_index :recipe_items, [:recipe_id, :product_id], unique: true
  end
end
