# frozen_string_literal: true

class User < ApplicationRecord
  MAX_FAILED_LOGINS = 5
  LOCKOUT_DURATION = 30.minutes
  PHONE_FORMAT = /\A\+?[0-9]{10,15}\z/

  has_secure_password
  has_one_attached :avatar

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

  before_validation :normalize_phone_number
  before_validation :sync_full_name

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :name, presence: true
  validates :phone_number, presence: true,
                           format: { with: PHONE_FORMAT, message: "must be 10–15 digits (optional leading +)" }
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
      first_name: first_name,
      last_name: last_name,
      name: name,
      phone_number: phone_number,
      timezone: timezone,
      settings: settings,
      onboarding_completed: ActiveModel::Type::Boolean.new.cast(settings["onboarding_completed"]) == true,
      avatar_url: avatar_url,
      initials: initials
    }
  end

  def avatar_url
    return nil unless avatar.attached?

    Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: false)
  rescue StandardError
    nil
  end

  def initials
    [ first_name, last_name ].map { |p| p.to_s.strip[0] }.compact_blank.join.upcase.presence ||
      email.to_s[0]&.upcase ||
      "?"
  end

  private

  def normalize_phone_number
    return if phone_number.blank?

    cleaned = phone_number.to_s.gsub(/[\s\-()]/, "")
    self.phone_number = cleaned
  end

  def sync_full_name
    parts = [ first_name, last_name ].map { |p| p.to_s.strip.presence }.compact
    self.name = parts.join(" ") if parts.any?
  end
end
