FactoryBot.define do
  factory :sponsor_banner do
    title { "ContentForce Pro" }
    description { "Профессиональный инструмент для автоматизации контента в Telegram" }
    url { "https://contentforce.ru" }
    enabled { false }

    trait :enabled do
      enabled { true }
    end

    trait :with_icon do
      after(:build) do |banner|
        banner.icon.attach(
          io: File.open(Rails.root.join("spec", "fixtures", "files", "test_image.png")),
          filename: "test_image.png",
          content_type: "image/png"
        )
      end
    end
  end
end
