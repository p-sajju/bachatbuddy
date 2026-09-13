# frozen_string_literal: true

require "rails_helper"

RSpec.describe MoneyLocks::UnlockService do
  let(:user) { create(:user) }
  let(:lock) { create(:money_lock, user: user, amount_paise: 10_000_00, remaining_paise: 10_000_00) }
  let(:service) { described_class.new(user, lock) }

  describe "normal unlock with cooling off" do
    it "creates cooling-off request and completes after wait" do
      req = service.request_unlock!(requested_amount_paise: 2_000_00, reason: "Need funds", urgency: "normal")
      expect(req.status).to eq("cooling_off")
      expect(lock.reload.status).to eq("unlock_requested")
      expect(MoneyLockUnlockEvent.where(event_type: "unlock_requested").count).to eq(1)

      Timecop.travel(req.cooling_off_until + 1.second) do
        service.complete_cooling_off!(req.id)
      end

      expect(req.reload.status).to eq("completed")
      expect(lock.reload.remaining_paise).to eq(8_000_00)
      expect(lock.status).to eq("active")
      expect(MoneyLockUnlockEvent.where(event_type: "cooling_off_unlocked").count).to eq(1)
    end

    it "cannot complete cooling-off before until" do
      req = service.request_unlock!(requested_amount_paise: 2_000_00, reason: "Need funds", urgency: "normal")

      expect {
        service.complete_cooling_off!(req.id)
      }.to raise_error(MoneyLocks::UnlockService::Conflict, /Cooling off not finished/)

      expect(req.reload.status).to eq("cooling_off")
      expect(lock.reload.remaining_paise).to eq(10_000_00)
    end
  end

  describe "emergency unlock" do
    it "requires UNLOCK confirmation phrase matching amount" do
      req = service.request_unlock!(requested_amount_paise: 3_000_00, reason: "Urgent", urgency: "emergency")
      expect(req.status).to eq("awaiting_confirm")
      expect(req.confirmation_phrase).to eq("UNLOCK 3000")

      expect {
        service.confirm_emergency!(unlock_request_id: req.id, confirmation: "WRONG")
      }.to raise_error(MoneyLocks::UnlockService::InvalidConfirmation)

      service.confirm_emergency!(unlock_request_id: req.id, confirmation: "UNLOCK 3000")
      expect(req.reload.status).to eq("completed")
      expect(lock.reload.remaining_paise).to eq(7_000_00)
      expect(MoneyLockUnlockEvent.where(event_type: "emergency_unlocked").count).to eq(1)
    end

    it "unlocks immediately via emergency_unlock_with_confirmation!" do
      req = service.emergency_unlock_with_confirmation!(
        requested_amount_paise: 2_500_00,
        reason: "Now",
        confirmation: "UNLOCK 2500"
      )
      expect(req.status).to eq("completed")
      expect(lock.reload.remaining_paise).to eq(7_500_00)
    end

    it "rejects concurrent/sequential double emergency confirm" do
      req = service.request_unlock!(requested_amount_paise: 4_000_00, reason: "Urgent", urgency: "emergency")

      service.confirm_emergency!(unlock_request_id: req.id, confirmation: "UNLOCK 4000")
      expect(lock.reload.remaining_paise).to eq(6_000_00)

      expect {
        service.confirm_emergency!(unlock_request_id: req.id, confirmation: "UNLOCK 4000")
      }.to raise_error(MoneyLocks::UnlockService::Conflict, /not awaiting confirmation/)

      expect(lock.reload.remaining_paise).to eq(6_000_00)
      expect(MoneyLockUnlockEvent.where(event_type: "emergency_unlocked").count).to eq(1)
    end
  end

  describe "preview" do
    it "uses remaining when amount is omitted" do
      preview = service.preview(requested_amount_paise: nil)
      expect(preview[:requested_amount_paise]).to eq(10_000_00)
      expect(preview[:remaining_after_paise]).to eq(0)
    end
  end

  describe "inactive locks" do
    it "cannot unlock cancelled or unlocked locks" do
      lock.update!(status: "cancelled")
      expect {
        service.request_unlock!(requested_amount_paise: 1_000_00, reason: "x", urgency: "normal")
      }.to raise_error(MoneyLocks::UnlockService::Conflict, /not active/)

      # keep remaining so amount resolution succeeds and status gate is exercised
      lock.update!(status: "unlocked")
      expect {
        service.emergency_unlock_with_confirmation!(
          requested_amount_paise: 1_000_00,
          reason: "x",
          confirmation: "UNLOCK 1000"
        )
      }.to raise_error(MoneyLocks::UnlockService::Conflict, /not active/)
    end
  end

  describe "partial unlock" do
    it "leaves remaining and keeps status active" do
      service.emergency_unlock_with_confirmation!(
        requested_amount_paise: 3_000_00,
        reason: "Partial",
        confirmation: "UNLOCK 3000"
      )
      expect(lock.reload.remaining_paise).to eq(7_000_00)
      expect(lock.status).to eq("active")
    end
  end
end
