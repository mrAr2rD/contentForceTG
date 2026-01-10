FactoryBot.define do
  factory :project do
    name { "MyString" }
    description { "MyText" }
    user { nil }
    status { 1 }
  end
end
