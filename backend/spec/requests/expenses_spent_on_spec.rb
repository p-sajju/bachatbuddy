# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Expenses spent_on alias", type: :request do
  let(:user) { create(:user) }
  let(:headers) do
    auth_headers_for(user).merge("CONTENT_TYPE" => "application/json")
  end

  it "accepts spent_on and stores it as occurred_on" do
    payload = {
      amount_paise: 250_00,
      spent_on: "2026-09-10",
      note: "Alias check"
    }.to_json

    post "/api/v1/expenses", params: payload, headers: headers

    expect(response).to have_http_status(:created)
    data = json_body["data"]
    expect(data["occurred_on"]).to eq("2026-09-10")
    expect(data["spent_on"]).to eq("2026-09-10")
    expect(Expense.last.occurred_on).to eq(Date.new(2026, 9, 10))
  end
end
