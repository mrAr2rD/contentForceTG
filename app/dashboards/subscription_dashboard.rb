require "administrate/base_dashboard"

class SubscriptionDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::String.with_options(searchable: false),
    user: Field::BelongsTo,
    plan: Field::Select.with_options(collection: Subscription.plans.keys),
    status: Field::Select.with_options(collection: Subscription.statuses.keys),
    current_period_start: Field::DateTime,
    current_period_end: Field::DateTime,
    cancel_at_period_end: Field::Boolean,
    canceled_at: Field::DateTime,
    trial_ends_at: Field::DateTime,
    usage: Field::Text,
    limits: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    user
    plan
    status
    current_period_end
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    user
    plan
    status
    current_period_start
    current_period_end
    cancel_at_period_end
    canceled_at
    trial_ends_at
    usage
    limits
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    user
    plan
    status
    current_period_start
    current_period_end
    cancel_at_period_end
    canceled_at
    trial_ends_at
  ].freeze

  COLLECTION_FILTERS = %i[
  ].freeze
end
