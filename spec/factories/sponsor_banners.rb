FactoryBot.define do
  factory :sponsor_banner do
    title { "ContentForce Pro" }
    description { "Профессиональный инструмент для автоматизации контента в Telegram" }
    url { "https://contentforce.ru" }
    enabled { false }
    display_on { :public_pages }

    trait :enabled do
      enabled { true }
    end

    trait :for_dashboard do
      display_on { :dashboard }
    end

    trait :for_public do
      display_on { :public_pages }
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
