# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reports", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe "GET /api/v1/reports/monthly" do
    it "returns income, expenses, and net for the month" do
      Timecop.freeze(Time.zone.parse("2026-09-15 12:00:00")) do
        create(:income, user: user, amount_paise: 80_000_00, occurred_on: Date.new(2026, 9, 1))
        create(:income, user: user, amount_paise: 5_000_00, occurred_on: Date.new(2026, 9, 10))
        create(:expense, user: user, amount_paise: 12_000_00, occurred_on: Date.new(2026, 9, 5))
        create(:expense, user: user, amount_paise: 3_000_00, occurred_on: Date.new(2026, 9, 12))
        # outside month
        create(:expense, user: user, amount_paise: 99_000_00, occurred_on: Date.new(2026, 8, 31))

        get "/api/v1/reports/monthly", params: { month: "2026-09-01" }, headers: headers

        expect(response).to have_http_status(:ok)
        data = json_body["data"]
        expect(data["income_paise"]).to eq(85_000_00)
        expect(data["expenses_paise"]).to eq(15_000_00)
        expect(data["net_paise"]).to eq(70_000_00)
        expect(data["period"]["label"]).to eq("September 2026")
      end
    end
  end
end
