class Invitation < ApplicationRecord
  belongs_to :account
  before_create :generate_token
  validates :email, presence: true, uniqueness: { scope: :account_id }

  private

  def generate_token
    self.token = SecureRandom.hex(16)
  end
end
