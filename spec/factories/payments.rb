FactoryBot.define do
  factory :payment do
    user { nil }
    subscription { nil }
    amount { "9.99" }
    status { 1 }
    provider { "MyString" }
    provider_payment_id { "MyString" }
    metadata { "" }
    paid_at { "2026-01-17 20:56:00" }
  end
end
