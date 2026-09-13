# frozen_string_literal: true

require "rails_helper"

RSpec.describe "People", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user).merge("CONTENT_TYPE" => "application/json") }

  describe "POST /api/v1/people" do
    it "creates with relationship alias mapped to relation" do
      post "/api/v1/people",
           params: { name: "Riya", relationship: "friend", notes: "ignored" }.to_json,
           headers: headers

      expect(response).to have_http_status(:created)
      data = json_body["data"]
      expect(data["name"]).to eq("Riya")
      expect(data["relation"]).to eq("friend")
      expect(data["relationship"]).to eq("friend")
      expect(Person.last.relation).to eq("friend")
    end
  end

  describe "GET /api/v1/people/:id/summary" do
    it "returns category totals for the current month and total_spent_paise" do
      Timecop.freeze(Time.zone.parse("2026-09-15 12:00:00")) do
        person = create(:person, user: user, name: "Mom", relation: "family")
        food = create(:category, user: user, name: "Food", kind: "expense")
        travel = create(:category, user: user, name: "Travel", kind: "expense")

        create(:expense, user: user, person: person, category: food,
                         amount_paise: 500_00, occurred_on: Date.new(2026, 9, 5))
        create(:expense, user: user, person: person, category: food,
                         amount_paise: 300_00, occurred_on: Date.new(2026, 9, 8))
        create(:expense, user: user, person: person, category: travel,
                         amount_paise: 1_000_00, occurred_on: Date.new(2026, 9, 10))
        # prior month — excluded from monthly by_category
        create(:expense, user: user, person: person, category: food,
                         amount_paise: 200_00, occurred_on: Date.new(2026, 8, 20))

        get "/api/v1/people/#{person.id}/summary", headers: headers

        expect(response).to have_http_status(:ok)
        data = json_body["data"]
        expect(data["month"]).to eq("2026-09-01")
        expect(data["by_category"]).to eq([
          { "name" => "Travel", "amount_paise" => 1_000_00 },
          { "name" => "Food", "amount_paise" => 800_00 }
        ])
        # all-time total on person payload
        expect(data["total_spent_paise"]).to eq(2_000_00)
      end
    end
  end
end
