class CreateSuppliers < ActiveRecord::Migration[7.0]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :contact_name
      t.string :contact_email
      t.string :phone_number

      t.timestamps
    end
  end
end