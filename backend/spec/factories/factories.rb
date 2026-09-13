# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }
    password { "password123" }
    timezone { "Asia/Kolkata" }

    trait :with_defaults do
      after(:create) { |user| Onboarding::SeedDefaults.new(user).call }
    end
  end

  factory :category do
    user
    sequence(:name) { |n| "Category #{n}" }
    kind { "expense" }
  end

  factory :payment_source do
    user
    sequence(:name) { |n| "Source #{n}" }
    kind { "upi" }
  end

  factory :person do
    user
    sequence(:name) { |n| "Person #{n}" }
    relation { "family" }
  end

  factory :income do
    user
    amount_paise { 100_000_00 }
    occurred_on { Date.current }
    note { "Salary" }
  end

  factory :expense do
    user
    amount_paise { 500_00 }
    occurred_on { Date.current }
    note { "Tea" }
    category { association :category, user: user }
  end

  factory :savings_goal do
    user
    sequence(:name) { |n| "Goal #{n}" }
    target_paise { 100_000_00 }
    current_paise { 0 }
    monthly_contribution_paise { 5_000_00 }
    status { "active" }
  end

  factory :money_lock do
    user
    amount_paise { 10_000_00 }
    remaining_paise { 10_000_00 }
    purpose { "Emergency fund" }
    status { "active" }
    locked_at { Time.current }
  end

  factory :money_lock_unlock_request do
    user
    money_lock { association :money_lock, user: user }
    requested_amount_paise { 1_000_00 }
    reason { "Need cash" }
    urgency { "normal" }
    status { "cooling_off" }
    cooling_off_until { 24.hours.from_now }
  end

  factory :recurring_expense do
    user
    sequence(:name) { |n| "Rent #{n}" }
    amount_paise { 15_000_00 }
    frequency { "monthly" }
    day_of_month { 1 }
    next_occurrence_on { Date.current.beginning_of_month }
    active { true }
  end

  factory :budget do
    user
    category { association :category, user: user }
    amount_paise { 5_000_00 }
    period_month { Date.current.beginning_of_month }
  end

  factory :notification do
    user
    kind { "info" }
    title { "Hello" }
    body { "Body" }
    sequence(:dedupe_key) { |n| "dedupe-#{n}" }
  end

  factory :idempotency_key do
    user
    sequence(:key) { |n| "idem-#{n}" }
    request_path { "/api/v1/expenses" }
    request_method { "POST" }
    expires_at { 24.hours.from_now }
  end

  factory :refresh_token do
    user
    token_digest { Digest::SHA256.hexdigest(SecureRandom.hex(32)) }
    expires_at { 30.days.from_now }
  end
end
