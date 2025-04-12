class Invitation < ApplicationRecord
  belongs_to :account
  has_secure_token
  
  before_create :set_defaults
  after_create :send_invitation_email

  def confirm!
    update(confirmed_at: Time.current)
  end

  def confirmed?
    confirmed_at.present?
  end

  def expired?
    created_at < 7.days.ago
  end

  private

  def set_defaults
    self.accepted = false
    self.token ||= SecureRandom.urlsafe_base64
  end

  def send_invitation_email
    InvitationMailer.invite(self).deliver_later
  end
end