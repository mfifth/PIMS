FactoryBot.define do
    factory :recipe do
      uid { SecureRandom.uuid }
      name { Faker::Food.dish }
      association :account
    end
end