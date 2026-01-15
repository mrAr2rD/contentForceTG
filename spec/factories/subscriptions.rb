FactoryBot.define do
  factory :subscription do
    user { nil }
    plan { 1 }
    status { 1 }
    current_period_start { "2026-01-15 15:37:00" }
    current_period_end { "2026-01-15 15:37:00" }
    cancel_at_period_end { false }
    canceled_at { "2026-01-15 15:37:00" }
    trial_ends_at { "2026-01-15 15:37:00" }
    usage { "" }
    limits { "" }
  end
end
