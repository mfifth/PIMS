module Types
  class BatchType < Types::BaseObject
    field :id, ID, null: false
    field :batch_number, String, null: true
    field :category, String, null: true
    field :notification_days_before_expiration, Integer, null: true
    field :expiration_date, Date, null: true
    field :manufactured_date, Date, null: true
  end
end