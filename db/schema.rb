# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_24_005201) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_configurations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "custom_system_prompt"
    t.string "default_model", default: "claude-3-sonnet", null: false
    t.jsonb "enabled_features", default: {}
    t.jsonb "fallback_models", default: ["gpt-3.5-turbo"]
    t.integer "max_tokens", default: 2000
    t.text "openrouter_api_key"
    t.decimal "temperature", precision: 3, scale: 2, default: "0.7"
    t.datetime "updated_at", null: false
    t.index ["default_model"], name: "index_ai_configurations_on_default_model"
  end

  create_table "ai_usage_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "cost", precision: 10, scale: 6, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "model_used", null: false
    t.uuid "project_id"
    t.integer "purpose", default: 0, null: false
    t.integer "tokens_used", default: 0, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["created_at"], name: "index_ai_usage_logs_on_created_at"
    t.index ["model_used"], name: "index_ai_usage_logs_on_model_used"
    t.index ["project_id"], name: "index_ai_usage_logs_on_project_id"
    t.index ["purpose"], name: "index_ai_usage_logs_on_purpose"
    t.index ["user_id", "created_at"], name: "index_ai_usage_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_ai_usage_logs_on_user_id"
  end

  create_table "channel_subscriber_metrics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "churn_rate", precision: 5, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "measured_at", null: false
    t.integer "subscriber_count", default: 0
    t.integer "subscriber_growth", default: 0
    t.uuid "telegram_bot_id", null: false
    t.datetime "updated_at", null: false
    t.index ["measured_at"], name: "index_channel_subscriber_metrics_on_measured_at"
    t.index ["telegram_bot_id", "measured_at"], name: "idx_on_telegram_bot_id_measured_at_8fab0e2fc4"
    t.index ["telegram_bot_id"], name: "index_channel_subscriber_metrics_on_telegram_bot_id"
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.integer "invoice_number"
    t.jsonb "metadata", default: {}
    t.datetime "paid_at"
    t.string "provider", null: false
    t.string "provider_payment_id"
    t.integer "status", default: 0, null: false
    t.uuid "subscription_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["invoice_number"], name: "index_payments_on_invoice_number", unique: true
    t.index ["provider_payment_id"], name: "index_payments_on_provider_payment_id"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["subscription_id"], name: "index_payments_on_subscription_id"
    t.index ["user_id", "created_at"], name: "index_payments_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "post_analytics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "button_clicks", default: {}
    t.datetime "created_at", null: false
    t.integer "forwards", default: 0
    t.datetime "measured_at", null: false
    t.uuid "post_id", null: false
    t.jsonb "reactions", default: {}
    t.string "telegram_message_id"
    t.datetime "updated_at", null: false
    t.integer "views", default: 0
    t.index ["measured_at"], name: "index_post_analytics_on_measured_at"
    t.index ["post_id", "measured_at"], name: "index_post_analytics_on_post_id_and_measured_at"
    t.index ["post_id"], name: "index_post_analytics_on_post_id"
    t.index ["telegram_message_id"], name: "index_post_analytics_on_telegram_message_id"
  end

  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "button_text"
    t.string "button_url"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "post_type", default: 0, null: false
    t.uuid "project_id"
    t.datetime "published_at"
    t.datetime "scheduled_at"
    t.integer "status"
    t.uuid "telegram_bot_id"
    t.bigint "telegram_message_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["post_type"], name: "index_posts_on_post_type"
    t.index ["project_id"], name: "index_posts_on_project_id"
    t.index ["telegram_bot_id"], name: "index_posts_on_telegram_bot_id"
    t.index ["telegram_message_id"], name: "index_posts_on_telegram_message_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ai_model", default: "anthropic/claude-3.5-sonnet"
    t.decimal "ai_temperature", precision: 3, scale: 2, default: "0.7"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "status"
    t.text "system_prompt"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.string "writing_style", default: "professional"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "cancel_at_period_end", default: false
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.jsonb "limits", default: {}
    t.integer "plan", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "trial_ends_at"
    t.datetime "updated_at", null: false
    t.jsonb "usage", default: {}
    t.uuid "user_id", null: false
    t.index ["plan"], name: "index_subscriptions_on_plan"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "telegram_bots", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "bot_token"
    t.string "bot_username"
    t.string "channel_id"
    t.string "channel_name"
    t.datetime "created_at", null: false
    t.jsonb "permissions", default: {}
    t.uuid "project_id", null: false
    t.jsonb "settings", default: {}
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false, null: false
    t.datetime "verified_at"
    t.index ["channel_id"], name: "index_telegram_bots_on_channel_id"
    t.index ["project_id"], name: "index_telegram_bots_on_project_id"
    t.index ["verified"], name: "index_telegram_bots_on_verified"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.bigint "telegram_id"
    t.string "telegram_username"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["telegram_id"], name: "index_users_on_telegram_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_usage_logs", "projects"
  add_foreign_key "ai_usage_logs", "users"
  add_foreign_key "channel_subscriber_metrics", "telegram_bots"
  add_foreign_key "payments", "subscriptions"
  add_foreign_key "payments", "users"
  add_foreign_key "post_analytics", "posts"
  add_foreign_key "posts", "projects"
  add_foreign_key "posts", "telegram_bots"
  add_foreign_key "posts", "users"
  add_foreign_key "projects", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "telegram_bots", "projects"
end
