require "administrate/base_dashboard"

class ProjectDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::String.with_options(searchable: false),
    user: Field::BelongsTo,
    name: Field::String,
    description: Field::Text,
    status: Field::Select.with_options(collection: Project.statuses.keys),
    telegram_bots: Field::HasMany,
    posts: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    user
    status
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    user
    name
    description
    status
    telegram_bots
    posts
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    user
    name
    description
    status
  ].freeze

  COLLECTION_FILTERS = %i[
  ].freeze
end
