class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :stripe_subscription_id
      t.string :plan
      t.string :status
      t.datetime :started_at
      t.datetime :ends_at

      t.timestamps
    end
  end
end
