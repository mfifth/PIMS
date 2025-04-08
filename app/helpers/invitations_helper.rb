module InvitationsHelper
  def invitation_email_if_present(token)
    Invitation.find_by(token: token)&.email
  end
end
