class AddRelationshipsToUser < ActiveRecord::Migration[8.0]
  def change
    add_reference :locations, :user
    add_reference :suppliers, :user
  end
end
