# frozen_string_literal: true

class User < ApplicationRecord
  MAX_FAILED_LOGINS = 5
  LOCKOUT_DURATION = 30.minutes

  has_secure_password

  has_many :refresh_tokens, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :payment_sources, dependent: :destroy
  has_many :incomes, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :people, dependent: :destroy
  has_many :savings_goals, dependent: :destroy
  has_many :money_locks, dependent: :destroy
  has_many :money_lock_unlock_requests, dependent: :destroy
  has_many :money_lock_unlock_events, dependent: :destroy
  has_many :recurring_expenses, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :idempotency_keys, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :timezone, presence: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  def locked?
    locked_at.present? && locked_at > LOCKOUT_DURATION.ago
  end

  def register_failed_login!
    increment!(:failed_login_count)
    update!(locked_at: Time.current) if failed_login_count >= MAX_FAILED_LOGINS
  end

  def clear_failed_logins!
    update!(failed_login_count: 0, locked_at: nil)
  end

  def as_api_json
    {
      id: id,
      email: email,
      name: name,
      timezone: timezone,
      settings: settings,
      onboarding_completed: ActiveModel::Type::Boolean.new.cast(settings["onboarding_completed"]) == true
    }
  end
end
