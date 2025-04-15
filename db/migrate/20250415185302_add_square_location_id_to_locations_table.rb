class AddSquareLocationIdToLocationsTable < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :square_location_id, :string
  end
end
