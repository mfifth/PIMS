class Batch < ApplicationRecord
  has_many :inventory_items
  has_many :products, through: :inventory_items

  belongs_to :account

  validates :expiration_date, presence: true
  validates :batch_number, presence: true, uniqueness: { scope: :account_id }

  def batch_info
    "#{batch_number} - MFG: #{manufactured_date || 'N/A'} | EXP: #{expiration_date || 'N/A'}"
  end

  def expiring_soon?
    expiration_date.in?(Date.current..(Date.current + 7.days))
  end

  scope :not_expired, -> { where('expiration_date >= ?', Date.current) }

  scope :search, -> (term) {
    return all if term.blank?

    query = "%#{term.downcase}%"
    adapter = ActiveRecord::Base.connection.adapter_name.downcase

    condition = if adapter.include?('postgresql')
      "LOWER(products.name) LIKE :q OR LOWER(batch_number) LIKE :q OR TO_CHAR(expiration_date, 'YYYY-MM-DD') LIKE :q"
    else
      "LOWER(products.name) LIKE :q OR LOWER(batch_number) LIKE :q OR strftime('%Y-%m-%d', expiration_date) LIKE :q"
    end

    left_joins(:products).distinct.where(condition, q: query)
  }
end
