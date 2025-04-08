class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @invite_url = accept_invitation_url(token: invitation.token)
    mail(to: invitation.email, subject: "You're invited to join!")
  end
end
