# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user).merge("CONTENT_TYPE" => "application/json") }

  it "marks a notification as read" do
    notification = create(:notification, user: user, read_at: nil)

    patch "/api/v1/notifications/#{notification.id}",
          params: { mark_read: true }.to_json,
          headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body["data"]["read_at"]).to be_present
    expect(notification.reload.read_at).to be_present
  end
end
