FactoryBot.define do
  factory :channel_subscriber_metric do
    telegram_bot { nil }
    subscriber_count { 1 }
    subscriber_growth { 1 }
    churn_rate { "9.99" }
    measured_at { "2026-01-16 00:15:41" }
  end
end
