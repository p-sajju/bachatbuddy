# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  it "validates email uniqueness (case-insensitive)" do
    create(:user, email: "Unique@Example.com")
    dup = build(:user, email: "unique@example.com")

    expect(dup).not_to be_valid
    expect(dup.errors[:email]).to be_present
  end

  it "allows distinct emails" do
    create(:user, email: "a@example.com")
    other = build(:user, email: "b@example.com")
    expect(other).to be_valid
  end
end
