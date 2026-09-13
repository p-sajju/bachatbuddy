# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Savings goals", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user).merge("CONTENT_TYPE" => "application/json") }

  describe "POST /api/v1/savings_goals" do
    it "creates a goal and includes suggested_contribution_paise" do
      post "/api/v1/savings_goals",
           params: {
             name: "Emergency",
             target_paise: 100_000_00,
             monthly_contribution_paise: 5_000_00,
             purpose: "Rainy day"
           }.to_json,
           headers: headers

      expect(response).to have_http_status(:created)
      data = json_body["data"]
      expect(data["name"]).to eq("Emergency")
      expect(data["target_paise"]).to eq(100_000_00)
      expect(data["current_paise"]).to eq(0)
      expect(data["status"]).to eq("active")
      expect(data).to have_key("suggested_contribution_paise")
      expect(data["suggested_contribution_paise"]).to eq(5_000_00)
    end
  end

  describe "POST /api/v1/savings_goals/:id/contribute" do
    let!(:goal) do
      create(:savings_goal, user: user, target_paise: 10_000_00, current_paise: 0,
                            monthly_contribution_paise: 2_000_00)
    end

    it "increases current_paise" do
      post "/api/v1/savings_goals/#{goal.id}/contribute",
           params: { amount_paise: 3_000_00 }.to_json,
           headers: headers

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["current_paise"]).to eq(3_000_00)
      expect(data["suggested_contribution_paise"]).to be_a(Integer)
      expect(goal.reload.current_paise).to eq(3_000_00)
      expect(goal.status).to eq("active")
    end

    it "rejects zero contribution" do
      post "/api/v1/savings_goals/#{goal.id}/contribute",
           params: { amount_paise: 0 }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"].first["code"]).to eq("invalid_amount")
      expect(goal.reload.current_paise).to eq(0)
    end

    it "rejects negative contribution" do
      post "/api/v1/savings_goals/#{goal.id}/contribute",
           params: { amount_paise: -500 }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"].first["code"]).to eq("invalid_amount")
    end

    it "marks the goal completed when target is reached" do
      post "/api/v1/savings_goals/#{goal.id}/contribute",
           params: { amount_paise: 10_000_00 }.to_json,
           headers: headers

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["current_paise"]).to eq(10_000_00)
      expect(data["status"]).to eq("completed")
      expect(goal.reload.status).to eq("completed")
    end
  end
end
