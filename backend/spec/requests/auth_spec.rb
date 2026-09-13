# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth", type: :request do
  let(:json_headers) { { "CONTENT_TYPE" => "application/json" } }

  describe "POST /api/v1/auth/signup" do
    it "creates a user and seeds categories and payment sources" do
      payload = {
        email: "newuser@example.com",
        password: "password123",
        name: "New User",
        timezone: "Asia/Kolkata"
      }.to_json

      expect {
        post "/api/v1/auth/signup", params: payload, headers: json_headers
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      data = json_body["data"]
      expect(data["user"]["email"]).to eq("newuser@example.com")
      expect(data["access_token"]).to be_present
      expect(data["refresh_token"]).to be_present

      user = User.find_by!(email: "newuser@example.com")
      expect(user.categories.count).to be > 0
      expect(user.payment_sources.count).to be > 0
      expect(user.categories.where(kind: "expense").count).to eq(Onboarding::SeedDefaults::DEFAULT_EXPENSE_CATEGORIES.size)
      expect(user.categories.where(kind: "income").count).to eq(Onboarding::SeedDefaults::DEFAULT_INCOME_CATEGORIES.size)
      expect(user.payment_sources.count).to eq(Onboarding::SeedDefaults::DEFAULT_PAYMENT_SOURCES.size)
    end

    it "rejects duplicate email" do
      create(:user, email: "taken@example.com")

      post "/api/v1/auth/signup",
           params: { email: "taken@example.com", password: "password123", name: "Dup" }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"].first["code"]).to eq("signup_failed")
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "login@example.com", password: "password123") }

    it "logs in with valid credentials" do
      post "/api/v1/auth/login",
           params: { email: "login@example.com", password: "password123" }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["user"]["id"]).to eq(user.id)
      expect(data["access_token"]).to be_present
      expect(data["refresh_token"]).to be_present
    end

    it "rejects wrong password" do
      post "/api/v1/auth/login",
           params: { email: "login@example.com", password: "wrong-password" }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["errors"].first["code"]).to eq("invalid_credentials")
      expect(user.reload.failed_login_count).to eq(1)
    end

    it "rejects unknown email" do
      post "/api/v1/auth/login",
           params: { email: "nobody@example.com", password: "password123" }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["errors"].first["code"]).to eq("invalid_credentials")
    end

    it "locks the account after MAX_FAILED_LOGINS failed attempts" do
      User::MAX_FAILED_LOGINS.times do
        post "/api/v1/auth/login",
             params: { email: "login@example.com", password: "bad" }.to_json,
             headers: json_headers
        expect(response).to have_http_status(:unauthorized)
      end

      expect(user.reload.locked?).to eq(true)

      post "/api/v1/auth/login",
           params: { email: "login@example.com", password: "password123" }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:locked)
      expect(json_body["errors"].first["code"]).to eq("account_locked")
    end
  end

  describe "POST /api/v1/auth/refresh" do
    let!(:user) { create(:user) }

    it "rotates the refresh token and rejects the revoked one" do
      tokens = Auth::TokenIssuer.new(user).issue_pair!
      old_refresh = tokens[:refresh_token]

      post "/api/v1/auth/refresh",
           params: { refresh_token: old_refresh }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:ok)
      new_refresh = json_body["data"]["refresh_token"]
      expect(new_refresh).to be_present
      expect(new_refresh).not_to eq(old_refresh)
      expect(json_body["data"]["access_token"]).to be_present

      post "/api/v1/auth/refresh",
           params: { refresh_token: old_refresh }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["errors"].first["code"]).to eq("invalid_refresh")
    end
  end

  describe "POST /api/v1/auth/logout" do
    let!(:user) { create(:user) }

    it "revokes the refresh token" do
      tokens = Auth::TokenIssuer.new(user).issue_pair!
      refresh = tokens[:refresh_token]

      post "/api/v1/auth/logout",
           params: { refresh_token: refresh }.to_json,
           headers: auth_headers_for(user).merge(json_headers)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["logged_out"]).to eq(true)

      post "/api/v1/auth/refresh",
           params: { refresh_token: refresh }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["errors"].first["code"]).to eq("invalid_refresh")
    end
  end
end
