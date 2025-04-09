module Types
  class BatchType < Types::BaseObject
    field :id, ID, null: false
    field :batch_number, String, null: true
    field :category, String, null: true
    field :notification_days_before_expiration, Integer, null: true
    field :expiration_date, Types::DateType, null: true
    field :manufactured_date, Types::DateType, null: true
  end
end