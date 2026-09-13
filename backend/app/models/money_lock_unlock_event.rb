# frozen_string_literal: true

class MoneyLockUnlockEvent < ApplicationRecord
  self.record_timestamps = false

  belongs_to :money_lock
  belongs_to :user
  belongs_to :unlock_request, class_name: "MoneyLockUnlockRequest", optional: true

  validates :event_type, presence: true

  before_create :set_created_at

  def as_api_json
    {
      id: id,
      money_lock_id: money_lock_id,
      unlock_request_id: unlock_request_id,
      event_type: event_type,
      kind: event_type,
      note: metadata.is_a?(Hash) ? metadata["reason"] || metadata[:reason] : nil,
      amount_paise: amount_paise,
      metadata: metadata,
      created_at: created_at
    }
  end

  private

  def set_created_at
    self.created_at ||= Time.current
  end
end
