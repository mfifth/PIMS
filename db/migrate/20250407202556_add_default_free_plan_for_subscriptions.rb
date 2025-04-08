class AddDefaultFreePlanForSubscriptions < ActiveRecord::Migration[8.0]
  def change
    change_column_default :subscriptions, :plan, from: '', to: 'free'
  end
end
