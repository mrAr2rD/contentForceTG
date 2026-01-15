FactoryBot.define do
  factory :ai_configuration do
    default_model { "MyString" }
    fallback_models { "" }
    temperature { "9.99" }
    max_tokens { 1 }
    custom_system_prompt { "MyText" }
    enabled_features { "" }
  end
end
