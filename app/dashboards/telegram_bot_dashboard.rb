require "administrate/base_dashboard"

class TelegramBotDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::String.with_options(searchable: false),
    project: Field::BelongsTo,
    bot_username: Field::String,
    channel_id: Field::String,
    channel_name: Field::String,
    verified: Field::Boolean,
    verified_at: Field::DateTime,
    posts: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    bot_username
    project
    channel_name
    verified
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    project
    bot_username
    channel_id
    channel_name
    verified
    verified_at
    posts
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    project
    bot_username
    channel_id
    channel_name
    verified
  ].freeze

  COLLECTION_FILTERS = %i[
  ].freeze
end
