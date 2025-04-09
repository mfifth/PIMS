# app/graphql/types/product_type.rb
module Types
  class ProductType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: true
    field :sku, String, null: true
    field :price, Float, null: true
    field :category, String, null: true
    field :batch_id, Integer, null: true
  end
end
