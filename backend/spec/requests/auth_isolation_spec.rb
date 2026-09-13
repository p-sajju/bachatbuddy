# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth isolation", type: :request do
  let(:user_a) { create(:user) }
  let(:user_b) { create(:user) }
  let!(:expense_b) { create(:expense, user: user_b, amount_paise: 999_00) }

  it "does not allow user A to read user B expense" do
    get "/api/v1/expenses/#{expense_b.id}", headers: auth_headers_for(user_a)
    expect(response).to have_http_status(:not_found)
    expect(json_body["errors"].first["code"]).to eq("not_found")
  end

  it "allows user B to read their own expense" do
    get "/api/v1/expenses/#{expense_b.id}", headers: auth_headers_for(user_b)
    expect(response).to have_http_status(:ok)
    expect(json_body["data"]["id"]).to eq(expense_b.id)
  end

  it "scopes money locks by user" do
    lock_b = create(:money_lock, user: user_b)
    get "/api/v1/money_locks/#{lock_b.id}", headers: auth_headers_for(user_a)
    expect(response).to have_http_status(:not_found)
  end
end
