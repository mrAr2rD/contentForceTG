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

ActiveRecord::Schema[8.1].define(version: 2026_01_11_020040) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.uuid "project_id", null: false
    t.datetime "published_at"
    t.integer "status"
    t.uuid "telegram_bot_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["project_id"], name: "index_posts_on_project_id"
    t.index ["telegram_bot_id"], name: "index_posts_on_telegram_bot_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_projects_on_user_id"
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
    t.index ["bot_username"], name: "index_telegram_bots_on_bot_username", unique: true
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

  add_foreign_key "posts", "projects"
  add_foreign_key "posts", "telegram_bots"
  add_foreign_key "posts", "users"
  add_foreign_key "projects", "users"
  add_foreign_key "telegram_bots", "projects"
end
