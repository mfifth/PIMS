module Mutations
  class UpdateBatch < BaseMutation
    argument :id, ID, required: true
    argument :batch_number, String, required: false
    argument :notification_days_before_expiration, Integer, required: false
    argument :manufactured_date, Date, required: false
    argument :expiration_date, Date, required: false

    type Types::BatchType

    def resolve(id:, batch_number: nil, notification_days_before_expiration: nil, manufactured_date: nil, expiration_date: nil)
      # Find the batch by id
      batch = Batch.find(id)

      # Update the batch with provided fields
      batch.update!(
        batch_number: batch_number,
        notification_days_before_expiration: notification_days_before_expiration,
        manufactured_date: manufactured_date,
        expiration_date: expiration_date
      )

      # Return the updated batch
      batch
    end
  end
end
