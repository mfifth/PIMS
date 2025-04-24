FactoryBot.define do
    factory :location do
      name { Faker::Address.community }
      address { Faker::Address.street_address }
      city { Faker::Address.city }
      state { Faker::Address.state_abbr }
      zip_code { Faker::Address.zip }
      country { Faker::Address.country }
      association :account
    end
end