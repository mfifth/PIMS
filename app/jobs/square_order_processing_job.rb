class SquareOrderProcessingJob < ApplicationJob
    include SquareHelper
    queue_as :default
  
    def self.unique_key(account_id, data)
      "order_#{data['id']}"
    end
  
    def self.unique_for
      24.hours
    end
  
    def perform(account_id, data)
      account = Account.find(account_id)
      process_order(account, data)
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error("OrderProcessingJob failed: #{e.message}")
      raise
    end
end