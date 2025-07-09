class AddAcceptedTermsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :accepted_terms, :boolean
  end
end
