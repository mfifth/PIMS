class ApplicationMailer < ActionMailer::Base
  default from: ENV['MAILJET_FROM_EMAIL']
  layout "mailer"
end
