# app/graphql/mutations/update_product.rb
module Mutations
  class UpdateProduct < BaseMutation
    argument :id, ID, required: true
    argument :name, String, required: false
    argument :sku, String, required: false
    argument :category, String, required: false
    argument :price, Float, required: false

    type Types::ProductType

    def resolve(id:, name:, category:, price:, sku:)
      product = Product.find(id)
      product.update(name: name, category: category, price: price, sku: sku)
      product
    end
  end
end
