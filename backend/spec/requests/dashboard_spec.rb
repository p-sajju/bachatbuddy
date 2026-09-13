# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:user) { create(:user, :with_defaults) }

  it "returns the expected summary shape including insights" do
    create(:income, user: user, amount_paise: 50_000_00)
    create(:expense, user: user, amount_paise: 1_000_00)

    get "/api/v1/dashboard", headers: auth_headers_for(user)

    expect(response).to have_http_status(:ok)
    data = json_body["data"]

    expect(data).to include(
      "safe_to_spend_paise",
      "income_paise",
      "expenses_paise",
      "locked_paise",
      "saved_paise",
      "period",
      "breakdown",
      "top_spending",
      "protected_locks",
      "goals",
      "insights",
      "disclaimer"
    )
    expect(data["insights"]).to be_an(Array)
    expect(data["income_paise"]).to eq(50_000_00)
    expect(data["expenses_paise"]).to eq(1_000_00)
  end
end
