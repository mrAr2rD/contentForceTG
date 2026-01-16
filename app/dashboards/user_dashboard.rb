require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::String.with_options(searchable: false),
    email: Field::String,
    telegram_id: Field::Number,
    telegram_username: Field::String,
    first_name: Field::String,
    last_name: Field::String,
    role: Field::Select.with_options(collection: User.roles.keys),
    projects: Field::HasMany,
    posts: Field::HasMany,
    subscription: Field::HasOne,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    email
    telegram_username
    role
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    email
    telegram_id
    telegram_username
    first_name
    last_name
    role
    projects
    posts
    subscription
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    email
    telegram_username
    first_name
    last_name
    role
  ].freeze

  COLLECTION_FILTERS = %i[
  ].freeze
end
