class AddExtraCountsToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :extra_products_count, :integer
    add_column :subscriptions, :extra_locations_count, :integer
    add_column :subscriptions, :extra_recipes_count, :integer
    add_column :subscriptions, :extra_users_count, :integer
  end
end
