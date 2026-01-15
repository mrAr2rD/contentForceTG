FactoryBot.define do
  factory :post_analytic do
    post { nil }
    telegram_message_id { "MyString" }
    views { 1 }
    forwards { 1 }
    reactions { "" }
    button_clicks { "" }
    measured_at { "2026-01-16 00:15:33" }
  end
end
