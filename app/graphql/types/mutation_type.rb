# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :update_product, mutation: Mutations::UpdateProduct
    field :update_batch, mutation: Mutations::UpdateBatch
    field :update_inventory_item, mutation: Mutations::UpdateInventoryItem
  end
end
