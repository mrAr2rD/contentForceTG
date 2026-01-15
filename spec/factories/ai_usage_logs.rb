FactoryBot.define do
  factory :ai_usage_log do
    user { nil }
    project { nil }
    model_used { "MyString" }
    tokens_used { 1 }
    cost { "9.99" }
    purpose { 1 }
  end
end
