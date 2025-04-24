class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :uid, null: false
      t.string :name, null: false
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end

    add_index :recipes, :uid, unique: true
  end
end
