# app/mailers/contact_mailer.rb
class ContactMailer < ApplicationMailer
    default from: 'info@pimsco.tech' # Change this to your email
    
    def contact_email(name, email, message)
      @name = name
      @email = email
      @message = message
      
      mail(to: 'info@pimsco.tech', # Change this to your support email
           subject: "New Contact Form Submission")
    end
end