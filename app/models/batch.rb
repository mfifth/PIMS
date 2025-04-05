class Batch < ApplicationRecord
  has_many :products
  belongs_to :account
  belongs_to :supplier, optional: true

  validates :batch_number, presence: true
  validates :expiration_date, presence: true

  validates :batch_number, uniqueness: { scope: :account_id }

  def batch_info
    "#{batch_number} - MFG: #{manufactured_date || 'N/A'} | EXP: #{expiration_date || 'N/A'}"
  end

  scope :not_expired, -> { where('expiration_date >= ?', Date.today) }

end
