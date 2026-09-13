# frozen_string_literal: true

class MoneyLockUnlockRequest < ApplicationRecord
  URGENCIES = %w[normal emergency planned soon urgent].freeze
  STATUSES = %w[pending cooling_off awaiting_confirm completed cancelled rejected].freeze

  belongs_to :money_lock
  belongs_to :user
  has_many :unlock_events, class_name: "MoneyLockUnlockEvent",
                           foreign_key: :unlock_request_id,
                           dependent: :nullify,
                           inverse_of: :unlock_request

  validates :requested_amount_paise, numericality: { only_integer: true, greater_than: 0 }
  validates :reason, presence: true
  validates :urgency, inclusion: { in: URGENCIES }
  validates :status, inclusion: { in: STATUSES }

  def as_api_json
    {
      id: id,
      money_lock_id: money_lock_id,
      requested_amount_paise: requested_amount_paise,
      reason: reason,
      urgency: urgency,
      status: status,
      cooling_off_until: cooling_off_until,
      confirmation_phrase: confirmation_phrase
    }
  end
end
