class AddProductsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :products, :user, index: true
  end
end
