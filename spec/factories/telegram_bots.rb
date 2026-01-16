FactoryBot.define do
  factory :telegram_bot do
    project { nil }
    bot_token { "MyString" }
    bot_username { "MyString" }
    channel_id { "MyString" }
    channel_name { "MyString" }
    verified { false }
    verified_at { "2026-01-11 04:59:12" }
    permissions { "" }
    settings { "" }
  end
end
