FactoryBot.define do
    factory :recipe_item do
      association :recipe
      association :product
      quantity { rand(1.0..10.0).round(2) }
      unit { %w[unit grams ml tbsp].sample }
    end
end