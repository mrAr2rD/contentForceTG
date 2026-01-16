FactoryBot.define do
  factory :post do
    title { "MyString" }
    content { "MyText" }
    user { nil }
    project { nil }
    published_at { "2026-01-11 01:35:53" }
    status { 1 }
  end
end
