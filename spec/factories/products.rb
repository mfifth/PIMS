FactoryBot.define do
    factory :product do
      name { Faker::Commerce.product_name }
      sku { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
      description { Faker::Lorem.sentence }
      price { Faker::Commerce.price(range: 1.0..100.0) }
      perishable { [true, false].sample }
      unit_type { %w[unit pounds ounces liters].sample }
      association :account
    end
end