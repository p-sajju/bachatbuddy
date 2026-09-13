# frozen_string_literal: true

require "rails_helper"

RSpec.describe MoneyLock, type: :model do
  let(:user) { create(:user) }

  it "does not allow remaining_paise to go negative via validation" do
    lock = build(:money_lock, user: user, amount_paise: 1_000_00, remaining_paise: -1)
    expect(lock).not_to be_valid
    expect(lock.errors[:remaining_paise]).to be_present
  end

  it "allows zero remaining_paise" do
    lock = build(:money_lock, user: user, amount_paise: 1_000_00, remaining_paise: 0, status: "unlocked")
    expect(lock).to be_valid
  end
end
