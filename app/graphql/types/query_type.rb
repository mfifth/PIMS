# app/graphql/types/query_type.rb
module Types
  class QueryType < Types::BaseObject
    field :all_products, [ProductType], null: false, description: "Retrieve all products" do
      argument :query, String, required: false
    end

    field :all_batches, [ProductType], null: false, description: "Retrieve all batches" do
      argument :query, String, required: false
    end

    def all_products(query: nil)
      products = Current.account.products.all
      products = products.where("name LIKE ? OR sku LIKE ? or category LIKE ", "%#{query}%", "%#{query}%", "%#{query}%") if query
      products
    end

    def all_batches(query: nil)
      batches = Current.account.batches
      batches = batches.where("batch_number LIKE ? ", "%#{query}%") if query
      batches
    end
  end
end
