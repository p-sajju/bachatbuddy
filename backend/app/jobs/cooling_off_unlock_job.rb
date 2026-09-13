# frozen_string_literal: true

class CoolingOffUnlockJob < ApplicationJob
  queue_as :default

  def perform(unlock_request_id)
    req = MoneyLockUnlockRequest.find_by(id: unlock_request_id)
    return unless req
    return unless req.status == "cooling_off"

    MoneyLocks::UnlockService.new(req.user, req.money_lock).complete_cooling_off!(req.id)
  end
end
