require "administrate/base_dashboard"

class PostDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::String.with_options(searchable: false),
    user: Field::BelongsTo,
    project: Field::BelongsTo,
    telegram_bot: Field::BelongsTo,
    title: Field::String,
    content: Field::Text,
    status: Field::Select.with_options(collection: Post.statuses.keys),
    published_at: Field::DateTime,
    telegram_message_id: Field::Number,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    title
    user
    project
    status
    published_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    user
    project
    telegram_bot
    title
    content
    status
    published_at
    telegram_message_id
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    user
    project
    telegram_bot
    title
    content
    status
    published_at
  ].freeze

  COLLECTION_FILTERS = %i[
  ].freeze
end
