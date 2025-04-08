class AddConfirmedAtToInvitations < ActiveRecord::Migration[8.0]
  def change
    add_column :invitations, :confirmed_at, :datetime
  end
end
