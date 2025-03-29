class AddAccountIdToCategories < ActiveRecord::Migration[8.0]
  def change
    add_reference :categories, :account
  end
end
