FactoryBot.define do
    factory :inventory_item do
      association :product
      association :location
      quantity { rand(0..100) }
      low_threshold { rand(5..20) }
    end
end
  