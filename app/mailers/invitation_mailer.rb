class InvitationMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM_ADDRESS', 'no-reply@example.com')

  def invite(invitation)
    @invitation = invitation
    @url = invitation.confirmed? ? 
      accept_invitation_url(token: invitation.token) : 
      confirm_invitation_url(token: invitation.token)
    
    mail(to: invitation.email, subject: "You've been invited!")
  end

  # app/mailers/user_mailer.rb
  def confirmation_instructions(user)
    @user = user
    @confirmation_url = confirm_email_url(
      token: @user.confirmation_token,
      host: ENV.fetch('MAILER_HOST', 'localhost:3000')
    )
    @expiration_hours = 24
    
    mail(
      to: @user.email_address,
      subject: 'Confirm your email address'
    )
  end
end