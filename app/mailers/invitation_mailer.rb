class InvitationMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM_ADDRESS', 'no-reply@example.com')

  def invite(invitation)
    @invitation = invitation
    @url = new_user_url(
      invitation_token: invitation.token,
      email: invitation.email
    )

    mail(
      to: invitation.email,
      subject: "Join PIMS as an admin."
    )
  end

  def confirmation_instructions(user)
    @user = user
    @confirmation_url = confirm_email_url(token: @user.confirmation_token)
    @expiration_hours = 24
    
    mail(
      to: @user.email_address,
      subject: 'Confirm your email address'
    )
  end
end