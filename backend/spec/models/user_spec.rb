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

  it "requires first_name last_name and phone_number" do
    user = build(:user, first_name: "", last_name: "", phone_number: "")
    expect(user).not_to be_valid
    expect(user.errors[:first_name]).to be_present
    expect(user.errors[:last_name]).to be_present
    expect(user.errors[:phone_number]).to be_present
  end

  it "syncs full name from first and last" do
    user = create(:user, first_name: "Priya", last_name: "Sharma", phone_number: "9876543210")
    expect(user.name).to eq("Priya Sharma")
  end

  it "normalizes phone number spacing" do
    user = create(:user, phone_number: "+91 98765 43210")
    expect(user.phone_number).to eq("+919876543210")
  end
end
