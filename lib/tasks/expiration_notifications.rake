namespace :notifications do
    desc "Send expiration notifications"
    task send_expirations: :environment do
      ExpirationNotificationJob.perform_later
    end
end
  