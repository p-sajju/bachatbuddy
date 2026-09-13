# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Money locks", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user).merge("CONTENT_TYPE" => "application/json") }

  around do |example|
    Timecop.freeze(Time.zone.parse("2026-09-15 12:00:00")) { example.run }
  end

  describe "POST /api/v1/money_locks" do
    it "creates a lock that reduces STS and appears on the dashboard as locked" do
      create(:income, user: user, amount_paise: 100_000_00, occurred_on: Date.new(2026, 9, 1))
      before_sts = SafeToSpendCalculator.new(user, month: Date.new(2026, 9, 1)).call.safe_to_spend_paise

      post "/api/v1/money_locks",
           params: {
             amount_paise: 20_000_00,
             purpose: "Emergency fund",
             name: "Rainy day"
           }.to_json,
           headers: headers

      expect(response).to have_http_status(:created)
      lock_data = json_body["data"]
      expect(lock_data["remaining_paise"]).to eq(20_000_00)
      expect(lock_data["status"]).to eq("active")

      after_sts = SafeToSpendCalculator.new(user, month: Date.new(2026, 9, 1)).call.safe_to_spend_paise
      expect(after_sts).to eq(before_sts - 20_000_00)

      get "/api/v1/dashboard", headers: headers
      expect(response).to have_http_status(:ok)
      dash = json_body["data"]
      expect(dash["locked_paise"]).to eq(20_000_00)
      expect(dash["protected_locks"].map { |l| l["id"] }).to include(lock_data["id"])
    end
  end

  describe "unlock flows" do
    let!(:lock) do
      create(:money_lock, user: user, amount_paise: 10_000_00, remaining_paise: 10_000_00,
                          purpose: "Emergency fund")
    end

    it "unlock_preview without amount uses remaining" do
      post "/api/v1/money_locks/#{lock.id}/unlock_preview",
           params: { urgency: "normal" }.to_json,
           headers: headers

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["requested_amount_paise"]).to eq(10_000_00)
      expect(data["remaining_after_paise"]).to eq(0)
      expect(data["confirmation_phrase"]).to eq("UNLOCK 10000")
    end

    it "rejects wrong emergency confirmation phrase" do
      post "/api/v1/money_locks/#{lock.id}/emergency_unlock",
           params: {
             amount_paise: 3_000_00,
             reason: "Urgent need",
             confirmation: "WRONG PHRASE"
           }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"].first["code"]).to eq("invalid_confirmation")
      expect(lock.reload.remaining_paise).to eq(10_000_00)
    end

    it "emergency unlock with correct UNLOCK phrase unlocks immediately" do
      post "/api/v1/money_locks/#{lock.id}/emergency_unlock",
           params: {
             amount_paise: 3_000_00,
             reason: "Urgent need",
             confirmation: "UNLOCK 3000"
           }.to_json,
           headers: headers

      expect(response).to have_http_status(:created)
      data = json_body["data"]
      expect(data["request"]["status"]).to eq("completed")
      expect(data["lock"]["remaining_paise"]).to eq(7_000_00)
      expect(data["lock"]["status"]).to eq("active")
      expect(lock.reload.remaining_paise).to eq(7_000_00)
    end

    it "cannot unlock a cancelled lock" do
      lock.update!(status: "cancelled")

      post "/api/v1/money_locks/#{lock.id}/unlock_request",
           params: { amount_paise: 1_000_00, reason: "Try anyway", urgency: "normal" }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"].first["code"]).to eq("unlock_request_failed")
    end

    it "cannot unlock an already unlocked lock" do
      lock.update!(status: "unlocked", remaining_paise: 0)

      post "/api/v1/money_locks/#{lock.id}/emergency_unlock",
           params: {
             amount_paise: 1_000_00,
             reason: "Try anyway",
             confirmation: "UNLOCK 1000"
           }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"].first["code"]).to eq("emergency_unlock_failed")
    end

    it "partial unlock leaves remaining and status active" do
      post "/api/v1/money_locks/#{lock.id}/emergency_unlock",
           params: {
             amount_paise: 4_000_00,
             reason: "Partial",
             confirmation: "UNLOCK 4000"
           }.to_json,
           headers: headers

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["lock"]["remaining_paise"]).to eq(6_000_00)
      expect(json_body["data"]["lock"]["status"]).to eq("active")
      expect(lock.reload.status).to eq("active")
    end
  end
end
