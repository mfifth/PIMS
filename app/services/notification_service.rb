class NotificationService
  def self.send_sms(phone_number, message)
    client = Twilio::REST::Client.new

    client.messages.create(
      from: ENV['TWILIO_PHONE_NUMBER'], # your Twilio phone number
      to: phone_number, # recipient's phone number
      body: message # message body
    )
  end
end