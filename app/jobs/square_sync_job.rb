class SquareSyncJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    account = Account.find(account_id)
    SquareSyncService.new(account).sync_all
  end
end
