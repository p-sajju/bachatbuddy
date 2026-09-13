# frozen_string_literal: true

require "rails_helper"

RSpec.describe SuggestedContribution do
  let(:user) { create(:user) }

  it "uses monthly_contribution_paise when no target_date" do
    goal = create(:savings_goal, user: user, target_paise: 100_000_00, current_paise: 10_000_00,
                                 monthly_contribution_paise: 7_500_00, target_date: nil)
    expect(described_class.new(goal).call).to eq(7_500_00)
  end

  it "ceil-divides remaining by months when target_date present" do
    Timecop.freeze(Time.zone.parse("2026-09-15 12:00:00")) do
      goal = create(:savings_goal, user: user, target_paise: 100_000_00, current_paise: 10_000_00,
                                   monthly_contribution_paise: 0, target_date: Date.new(2026, 12, 31))
      # remaining 90_000_00 over Sep->Dec = 3 months => ceil(9000000/3)=3000000
      expect(described_class.new(goal).call).to eq(30_000_00)
    end
  end
end
