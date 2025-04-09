module Types
  class BatchType < Types::BaseObject
    field :id, ID, null: false
    field :batch_number, String, null: true
    field :category, String, null: true
    field :notification_days_before_expiration, Integer, null: true
    field :expiration_date, GraphQL::Types::ISO8601Date, null: true
    field :manufactured_date, GraphQL::Types::ISO8601Date, null: true
  end
end