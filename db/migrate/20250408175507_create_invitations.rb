class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.string :email
      t.string :token
      t.references :account, null: false, foreign_key: true
      t.string :role
      t.boolean :accepted

      t.timestamps
    end
  end
end
