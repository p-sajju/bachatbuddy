# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Idempotency", type: :request do
  let(:user) { create(:user) }
  let(:headers) do
    auth_headers_for(user).merge(
      "Idempotency-Key" => "exp-create-1",
      "CONTENT_TYPE" => "application/json"
    )
  end

  it "returns the same response for duplicate POSTs with the same key" do
    payload = { amount_paise: 250_00, occurred_on: Date.current.to_s, note: "Snacks" }.to_json

    post "/api/v1/expenses", params: payload, headers: headers
    expect(response).to have_http_status(:created)
    first = json_body
    expense_id = first["data"]["id"]

    expect {
      post "/api/v1/expenses", params: payload, headers: headers
    }.not_to change(Expense, :count)

    expect(response).to have_http_status(:created)
    expect(json_body["data"]["id"]).to eq(expense_id)
  end
end
