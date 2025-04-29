class CloverSyncJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    account = Account.find(account_id)
    CloverSyncService.new(account).sync_all
  end
end
