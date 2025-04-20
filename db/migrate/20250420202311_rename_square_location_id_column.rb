class RenameSquareLocationIdColumn < ActiveRecord::Migration[8.0]
  def change
    rename_column :locations, :square_location_id, :location_uid
  end
end
