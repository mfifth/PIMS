module Types
  class InventoryItemType < Types::BaseObject
    field :id, ID, null: false
    field :product_id, Integer, null: true
    field :quantity, Integer, null: true
    field :low_threshold, Integer, null: true
    field :location_id, Integer, null: true

    # If you want to include the associated Product, you can add a field like this:
    field :product, Types::ProductType, null: false, resolve: ->(obj, _, _) { obj.product }
  end
end
