# frozen_string_literal: true

class CreateBachatbuddySchema < ActiveRecord::Migration[8.0]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")
    enable_extension "citext" unless extension_enabled?("citext")

    create_table :users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.citext :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :timezone, null: false, default: "Asia/Kolkata"
      t.integer :failed_login_count, null: false, default: 0
      t.datetime :locked_at
      t.jsonb :settings, null: false, default: {}
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :refresh_tokens, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.uuid :replaced_by_id
      t.string :user_agent
      t.string :ip
      t.timestamps
    end
    add_index :refresh_tokens, :token_digest, unique: true
    add_index :refresh_tokens, :expires_at

    create_table :categories, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.string :name, null: false
      t.string :kind, null: false, default: "expense"
      t.string :icon
      t.integer :position, null: false, default: 0
      t.boolean :system, null: false, default: false
      t.timestamps
    end
    add_index :categories, [ :user_id, :name, :kind ], unique: true

    create_table :payment_sources, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.string :name, null: false
      t.string :kind, null: false, default: "other"
      t.boolean :system, null: false, default: false
      t.timestamps
    end
    add_index :payment_sources, [ :user_id, :name ], unique: true

    create_table :people, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.string :name, null: false
      t.string :relation
      t.timestamps
    end
    add_index :people, [ :user_id, :name ], unique: true

    create_table :savings_goals, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.string :name, null: false
      t.bigint :target_paise, null: false, default: 0
      t.bigint :current_paise, null: false, default: 0
      t.date :target_date
      t.bigint :monthly_contribution_paise, null: false, default: 0
      t.string :status, null: false, default: "active"
      t.string :purpose
      t.timestamps
    end
    add_index :savings_goals, [ :user_id, :status ]
    add_check_constraint :savings_goals, "target_paise >= 0", name: "savings_goals_target_nonneg"
    add_check_constraint :savings_goals, "current_paise >= 0", name: "savings_goals_current_nonneg"

    create_table :incomes, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.references :category, foreign_key: true, type: :uuid, index: true
      t.references :payment_source, foreign_key: true, type: :uuid, index: true
      t.bigint :amount_paise, null: false
      t.date :occurred_on, null: false
      t.string :note
      t.timestamps
    end
    add_index :incomes, [ :user_id, :occurred_on ]
    add_check_constraint :incomes, "amount_paise > 0", name: "incomes_amount_positive"

    create_table :recurring_expenses, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.references :category, foreign_key: true, type: :uuid, index: true
      t.references :payment_source, foreign_key: true, type: :uuid, index: true
      t.references :person, foreign_key: true, type: :uuid, index: true
      t.string :name, null: false
      t.bigint :amount_paise, null: false
      t.string :frequency, null: false, default: "monthly"
      t.integer :day_of_month
      t.integer :day_of_week
      t.date :next_occurrence_on, null: false
      t.date :last_materialized_on
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :recurring_expenses, [ :user_id, :active, :next_occurrence_on ]
    add_check_constraint :recurring_expenses, "amount_paise > 0", name: "recurring_expenses_amount_positive"

    create_table :expenses, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.references :category, foreign_key: true, type: :uuid, index: true
      t.references :payment_source, foreign_key: true, type: :uuid, index: true
      t.references :person, foreign_key: true, type: :uuid, index: true
      t.references :recurring_expense, foreign_key: true, type: :uuid, index: true
      t.bigint :amount_paise, null: false
      t.date :occurred_on, null: false
      t.string :note
      t.timestamps
    end
    add_index :expenses, [ :user_id, :occurred_on ]
    add_index :expenses, [ :user_id, :person_id, :occurred_on ]
    add_index :expenses, [ :recurring_expense_id, :occurred_on ],
              unique: true,
              where: "recurring_expense_id IS NOT NULL",
              name: "index_expenses_unique_materialized_recurring"
    add_check_constraint :expenses, "amount_paise > 0", name: "expenses_amount_positive"

    create_table :money_locks, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.references :savings_goal, foreign_key: true, type: :uuid, index: true
      t.bigint :amount_paise, null: false
      t.bigint :remaining_paise, null: false
      t.string :purpose
      t.string :status, null: false, default: "active"
      t.datetime :locked_at, null: false
      t.datetime :unlock_at
      t.datetime :expires_at
      t.string :note
      t.timestamps
    end
    add_index :money_locks, [ :user_id, :status ]
    add_check_constraint :money_locks, "amount_paise > 0", name: "money_locks_amount_positive"
    add_check_constraint :money_locks, "remaining_paise >= 0", name: "money_locks_remaining_nonneg"

    create_table :money_lock_unlock_requests, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :money_lock, null: false, foreign_key: true, type: :uuid, index: true
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.bigint :requested_amount_paise, null: false
      t.string :reason, null: false
      t.string :urgency, null: false, default: "normal"
      t.string :status, null: false, default: "pending"
      t.datetime :cooling_off_until
      t.string :confirmation_phrase
      t.timestamps
    end
    add_index :money_lock_unlock_requests, [ :money_lock_id, :status ]
    add_check_constraint :money_lock_unlock_requests, "requested_amount_paise > 0",
                         name: "unlock_requests_amount_positive"

    create_table :money_lock_unlock_events, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :money_lock, null: false, foreign_key: true, type: :uuid, index: true
      t.references :unlock_request, foreign_key: { to_table: :money_lock_unlock_requests }, type: :uuid, index: true
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.string :event_type, null: false
      t.bigint :amount_paise
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :money_lock_unlock_events, [ :money_lock_id, :created_at ]

    create_table :budgets, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.references :category, null: false, foreign_key: true, type: :uuid, index: true
      t.bigint :amount_paise, null: false
      t.date :period_month, null: false
      t.timestamps
    end
    add_index :budgets, [ :user_id, :category_id, :period_month ], unique: true
    add_check_constraint :budgets, "amount_paise >= 0", name: "budgets_amount_nonneg"

    create_table :notifications, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.string :kind, null: false
      t.string :title, null: false
      t.text :body
      t.datetime :read_at
      t.string :dedupe_key, null: false
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end
    add_index :notifications, [ :user_id, :dedupe_key ], unique: true
    add_index :notifications, [ :user_id, :read_at ]

    create_table :idempotency_keys, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.string :key, null: false
      t.string :request_path, null: false
      t.string :request_method, null: false
      t.integer :response_code
      t.jsonb :response_body
      t.string :request_digest
      t.datetime :locked_at
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :idempotency_keys, [ :user_id, :key ], unique: true
    add_index :idempotency_keys, :expires_at
  end
end
