# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Incomes and expenses", type: :request do
  let(:user) { create(:user, :with_defaults) }
  let(:headers) { auth_headers_for(user).merge("CONTENT_TYPE" => "application/json") }

  describe "POST /api/v1/incomes" do
    it "creates income using received_on alias" do
      payload = {
        amount_paise: 50_000_00,
        received_on: "2026-09-01",
        note: "Salary"
      }.to_json

      post "/api/v1/incomes", params: payload, headers: headers

      expect(response).to have_http_status(:created)
      data = json_body["data"]
      expect(data["occurred_on"]).to eq("2026-09-01")
      expect(data["received_on"]).to eq("2026-09-01")
      expect(data["amount_paise"]).to eq(50_000_00)
      expect(Income.last.occurred_on).to eq(Date.new(2026, 9, 1))
    end

    it "rejects amount_paise <= 0" do
      post "/api/v1/incomes",
           params: { amount_paise: 0, received_on: Date.current.to_s }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"].first["code"]).to eq("validation_failed")
    end

    it "rejects negative amount_paise" do
      post "/api/v1/incomes",
           params: { amount_paise: -100, occurred_on: Date.current.to_s }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/expenses" do
    it "creates expense with spent_on and optional person_id nil (Myself)" do
      category = user.categories.where(kind: "expense").first

      payload = {
        amount_paise: 250_00,
        spent_on: "2026-09-10",
        note: "Coffee",
        category_id: category&.id,
        person_id: nil
      }.to_json

      post "/api/v1/expenses", params: payload, headers: headers

      expect(response).to have_http_status(:created)
      data = json_body["data"]
      expect(data["occurred_on"]).to eq("2026-09-10")
      expect(data["spent_on"]).to eq("2026-09-10")
      expect(data["person_id"]).to be_nil
      expect(Expense.last.person_id).to be_nil
    end

    it "rejects amount_paise <= 0" do
      post "/api/v1/expenses",
           params: { amount_paise: 0, spent_on: Date.current.to_s }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"].first["code"]).to eq("validation_failed")
    end
  end

  describe "expense for person" do
    it "appears in person summary" do
      person = create(:person, user: user, name: "Asha")
      category = create(:category, user: user, name: "Gifts", kind: "expense")
      create(:expense, user: user, person: person, category: category,
                       amount_paise: 1_200_00, occurred_on: Date.current)

      get "/api/v1/people/#{person.id}/summary", headers: headers

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["id"]).to eq(person.id)
      expect(data["total_spent_paise"]).to eq(1_200_00)
      expect(data["by_category"]).to include(hash_including("name" => "Gifts", "amount_paise" => 1_200_00))
      expect(data["expenses"].size).to eq(1)
    end
  end

  describe "GET /api/v1/expenses pagination" do
    it "returns pagination meta" do
      create_list(:expense, 3, user: user)

      get "/api/v1/expenses", params: { page: 1, per_page: 2 }, headers: headers

      expect(response).to have_http_status(:ok)
      meta = json_body["meta"]
      expect(meta["page"]).to eq(1)
      expect(meta["per_page"]).to eq(2)
      expect(meta["total"]).to eq(3)
      expect(meta["total_pages"]).to eq(2)
      expect(json_body["data"].size).to eq(2)
    end
  end

  describe "PATCH /api/v1/expenses/:id" do
    it "returns 404 when updating another user's expense" do
      other = create(:user)
      foreign_expense = create(:expense, user: other, amount_paise: 999_00)

      patch "/api/v1/expenses/#{foreign_expense.id}",
            params: { note: "hijack" }.to_json,
            headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json_body["errors"].first["code"]).to eq("not_found")
      expect(foreign_expense.reload.note).not_to eq("hijack")
    end
  end
end
