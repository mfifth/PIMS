FactoryBot.define do
    factory :account do
      stripe_customer_id { SecureRandom.hex(8) }
      square_access_token { SecureRandom.hex(16) }
      square_merchant_id { "square_#{SecureRandom.hex(4)}" }
      square_refresh_token { SecureRandom.hex(16) }
      clover_access_token { SecureRandom.hex(16) }
      clover_merchant_id { "clover_#{SecureRandom.hex(4)}" }
    end
end