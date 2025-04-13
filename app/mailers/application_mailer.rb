class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAILER_FROM_ADDRESS', 'mfifth@gmail.com')
  layout "mailer"
end
