module Types
  class InventoryItemType < Types::BaseObject
    field :id, ID, null: false
    field :product_id, Integer, null: true
    field :quantity, Integer, null: true
    field :low_threshold, Integer, null: true
    field :location_id, Integer, null: true
  end
end
