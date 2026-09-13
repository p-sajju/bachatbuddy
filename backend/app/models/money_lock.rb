# frozen_string_literal: true

class MoneyLock < ApplicationRecord
  STATUSES = %w[active unlock_requested unlocked expired cancelled].freeze

  belongs_to :user
  belongs_to :savings_goal, optional: true
  has_many :unlock_requests, class_name: "MoneyLockUnlockRequest", dependent: :destroy
  has_many :unlock_events, class_name: "MoneyLockUnlockEvent", dependent: :destroy

  validates :amount_paise, numericality: { only_integer: true, greater_than: 0 }
  validates :remaining_paise, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :locked_at, presence: true

  scope :active_locks, -> { where(status: %w[active unlock_requested]) }
  scope :counting_toward_sts, -> { where(status: %w[active unlock_requested]) }

  def active_like?
    status.in?(%w[active unlock_requested])
  end

  def as_api_json
    {
      id: id,
      name: note.presence || purpose.presence || "Money lock",
      amount_paise: remaining_paise.positive? ? remaining_paise : amount_paise,
      remaining_paise: remaining_paise,
      amount_formatted: Money.format_paise(amount_paise),
      remaining_formatted: Money.format_paise(remaining_paise),
      purpose: purpose,
      status: status,
      locked_at: locked_at,
      unlock_at: unlock_at,
      unlock_available_at: unlock_at,
      expires_at: expires_at,
      note: note,
      savings_goal_id: savings_goal_id,
      created_at: created_at
    }
  end
end
