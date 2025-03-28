class Notification < ApplicationRecord
  validates :message, presence: true
  validates :notification_type, presence: true
  belongs_to :account
end
