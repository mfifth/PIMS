module Mutations
  class UpdateInventoryItem < BaseMutation
    argument :id, ID, required: false
    argument :quantity, Integer, required: true
    argument :low_threshold, Integer, required: false
    argument :location_id, Integer, required: true
    argument :product_id, Integer, required: true

    field :inventory_item, Types::InventoryItemType, null: false

    def resolve(id:, quantity:, low_threshold: nil, location_id:, product_id:)
      inventory_item = InventoryItem.find_by(location_id: location_id, product_id: product_id)
      inventory_item.update!(
        quantity: quantity,
        low_threshold: low_threshold
      )
      { inventory_item: inventory_item }
    end
  end
end
