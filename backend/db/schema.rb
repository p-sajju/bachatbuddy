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

ActiveRecord::Schema[8.0].define(version: 2026_09_13_160759) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "budgets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "category_id", null: false
    t.bigint "amount_paise", null: false
    t.date "period_month", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_budgets_on_category_id"
    t.index ["user_id", "category_id", "period_month"], name: "index_budgets_on_user_id_and_category_id_and_period_month", unique: true
    t.index ["user_id"], name: "index_budgets_on_user_id"
    t.check_constraint "amount_paise >= 0", name: "budgets_amount_nonneg"
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.string "kind", default: "expense", null: false
    t.string "icon"
    t.integer "position", default: 0, null: false
    t.boolean "system", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name", "kind"], name: "index_categories_on_user_id_and_name_and_kind", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "expenses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "category_id"
    t.uuid "payment_source_id"
    t.uuid "person_id"
    t.uuid "recurring_expense_id"
    t.bigint "amount_paise", null: false
    t.date "occurred_on", null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_expenses_on_category_id"
    t.index ["payment_source_id"], name: "index_expenses_on_payment_source_id"
    t.index ["person_id"], name: "index_expenses_on_person_id"
    t.index ["recurring_expense_id", "occurred_on"], name: "index_expenses_unique_materialized_recurring", unique: true, where: "(recurring_expense_id IS NOT NULL)"
    t.index ["recurring_expense_id"], name: "index_expenses_on_recurring_expense_id"
    t.index ["user_id", "occurred_on"], name: "index_expenses_on_user_id_and_occurred_on"
    t.index ["user_id", "person_id", "occurred_on"], name: "index_expenses_on_user_id_and_person_id_and_occurred_on"
    t.index ["user_id"], name: "index_expenses_on_user_id"
    t.check_constraint "amount_paise > 0", name: "expenses_amount_positive"
  end

  create_table "idempotency_keys", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "key", null: false
    t.string "request_path", null: false
    t.string "request_method", null: false
    t.integer "response_code"
    t.jsonb "response_body"
    t.string "request_digest"
    t.datetime "locked_at"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_idempotency_keys_on_expires_at"
    t.index ["user_id", "key"], name: "index_idempotency_keys_on_user_id_and_key", unique: true
    t.index ["user_id"], name: "index_idempotency_keys_on_user_id"
  end

  create_table "incomes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "category_id"
    t.uuid "payment_source_id"
    t.bigint "amount_paise", null: false
    t.date "occurred_on", null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_incomes_on_category_id"
    t.index ["payment_source_id"], name: "index_incomes_on_payment_source_id"
    t.index ["user_id", "occurred_on"], name: "index_incomes_on_user_id_and_occurred_on"
    t.index ["user_id"], name: "index_incomes_on_user_id"
    t.check_constraint "amount_paise > 0", name: "incomes_amount_positive"
  end

  create_table "money_lock_unlock_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "money_lock_id", null: false
    t.uuid "unlock_request_id"
    t.uuid "user_id", null: false
    t.string "event_type", null: false
    t.bigint "amount_paise"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["money_lock_id", "created_at"], name: "index_money_lock_unlock_events_on_money_lock_id_and_created_at"
    t.index ["money_lock_id"], name: "index_money_lock_unlock_events_on_money_lock_id"
    t.index ["unlock_request_id"], name: "index_money_lock_unlock_events_on_unlock_request_id"
    t.index ["user_id"], name: "index_money_lock_unlock_events_on_user_id"
  end

  create_table "money_lock_unlock_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "money_lock_id", null: false
    t.uuid "user_id", null: false
    t.bigint "requested_amount_paise", null: false
    t.string "reason", null: false
    t.string "urgency", default: "normal", null: false
    t.string "status", default: "pending", null: false
    t.datetime "cooling_off_until"
    t.string "confirmation_phrase"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["money_lock_id", "status"], name: "index_money_lock_unlock_requests_on_money_lock_id_and_status"
    t.index ["money_lock_id"], name: "index_money_lock_unlock_requests_on_money_lock_id"
    t.index ["user_id"], name: "index_money_lock_unlock_requests_on_user_id"
    t.check_constraint "requested_amount_paise > 0", name: "unlock_requests_amount_positive"
  end

  create_table "money_locks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "savings_goal_id"
    t.bigint "amount_paise", null: false
    t.bigint "remaining_paise", null: false
    t.string "purpose"
    t.string "status", default: "active", null: false
    t.datetime "locked_at", null: false
    t.datetime "unlock_at"
    t.datetime "expires_at"
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["savings_goal_id"], name: "index_money_locks_on_savings_goal_id"
    t.index ["user_id", "status"], name: "index_money_locks_on_user_id_and_status"
    t.index ["user_id"], name: "index_money_locks_on_user_id"
    t.check_constraint "amount_paise > 0", name: "money_locks_amount_positive"
    t.check_constraint "remaining_paise >= 0", name: "money_locks_remaining_nonneg"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "kind", null: false
    t.string "title", null: false
    t.text "body"
    t.datetime "read_at"
    t.string "dedupe_key", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "dedupe_key"], name: "index_notifications_on_user_id_and_dedupe_key", unique: true
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "payment_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.string "kind", default: "other", null: false
    t.boolean "system", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_payment_sources_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_payment_sources_on_user_id"
  end

  create_table "people", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.string "relation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_people_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_people_on_user_id"
  end

  create_table "recurring_expenses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "category_id"
    t.uuid "payment_source_id"
    t.uuid "person_id"
    t.string "name", null: false
    t.bigint "amount_paise", null: false
    t.string "frequency", default: "monthly", null: false
    t.integer "day_of_month"
    t.integer "day_of_week"
    t.date "next_occurrence_on", null: false
    t.date "last_materialized_on"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_recurring_expenses_on_category_id"
    t.index ["payment_source_id"], name: "index_recurring_expenses_on_payment_source_id"
    t.index ["person_id"], name: "index_recurring_expenses_on_person_id"
    t.index ["user_id", "active", "next_occurrence_on"], name: "idx_on_user_id_active_next_occurrence_on_4c652138af"
    t.index ["user_id"], name: "index_recurring_expenses_on_user_id"
    t.check_constraint "amount_paise > 0", name: "recurring_expenses_amount_positive"
  end

  create_table "refresh_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.uuid "replaced_by_id"
    t.string "user_agent"
    t.string "ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_refresh_tokens_on_expires_at"
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "savings_goals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.bigint "target_paise", default: 0, null: false
    t.bigint "current_paise", default: 0, null: false
    t.date "target_date"
    t.bigint "monthly_contribution_paise", default: 0, null: false
    t.string "status", default: "active", null: false
    t.string "purpose"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "status"], name: "index_savings_goals_on_user_id_and_status"
    t.index ["user_id"], name: "index_savings_goals_on_user_id"
    t.check_constraint "current_paise >= 0", name: "savings_goals_current_nonneg"
    t.check_constraint "target_paise >= 0", name: "savings_goals_target_nonneg"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.citext "email", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.string "timezone", default: "Asia/Kolkata", null: false
    t.integer "failed_login_count", default: 0, null: false
    t.datetime "locked_at"
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone_number", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "budgets", "categories"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "expenses", "categories"
  add_foreign_key "expenses", "payment_sources"
  add_foreign_key "expenses", "people"
  add_foreign_key "expenses", "recurring_expenses"
  add_foreign_key "expenses", "users"
  add_foreign_key "idempotency_keys", "users"
  add_foreign_key "incomes", "categories"
  add_foreign_key "incomes", "payment_sources"
  add_foreign_key "incomes", "users"
  add_foreign_key "money_lock_unlock_events", "money_lock_unlock_requests", column: "unlock_request_id"
  add_foreign_key "money_lock_unlock_events", "money_locks"
  add_foreign_key "money_lock_unlock_events", "users"
  add_foreign_key "money_lock_unlock_requests", "money_locks"
  add_foreign_key "money_lock_unlock_requests", "users"
  add_foreign_key "money_locks", "savings_goals"
  add_foreign_key "money_locks", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "payment_sources", "users"
  add_foreign_key "people", "users"
  add_foreign_key "recurring_expenses", "categories"
  add_foreign_key "recurring_expenses", "payment_sources"
  add_foreign_key "recurring_expenses", "people"
  add_foreign_key "recurring_expenses", "users"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "savings_goals", "users"
end
