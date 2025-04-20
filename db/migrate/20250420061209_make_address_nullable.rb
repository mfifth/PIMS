class MakeAddressNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :locations, :address, true
  end
end
