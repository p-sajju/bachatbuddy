# frozen_string_literal: true

require "rails_helper"

RSpec.describe SafeToSpendCalculator do
  let(:user) { create(:user) }
  let(:month) { Date.new(2026, 9, 1) }

  around do |example|
    Timecop.freeze(Time.zone.parse("2026-09-15 12:00:00")) { example.run }
  end

  it "computes canonical formula with breakdown and floors at zero" do
    create(:income, user: user, amount_paise: 100_000_00, occurred_on: Date.new(2026, 9, 1))
    create(:expense, user: user, amount_paise: 20_000_00, occurred_on: Date.new(2026, 9, 5))
    create(:money_lock, user: user, amount_paise: 30_000_00, remaining_paise: 30_000_00)
    create(:recurring_expense, user: user, amount_paise: 10_000_00, next_occurrence_on: Date.new(2026, 9, 20), last_materialized_on: nil)
    create(:savings_goal, user: user, target_paise: 50_000_00, current_paise: 0, monthly_contribution_paise: 5_000_00, target_date: nil)

    result = described_class.new(user, month: month).call

    expect(result.income_paise).to eq(100_000_00)
    expect(result.expense_paise).to eq(20_000_00)
    expect(result.locked_paise).to eq(30_000_00)
    expect(result.upcoming_recurring_paise).to eq(10_000_00)
    expect(result.planned_savings_paise).to eq(5_000_00)
    expect(result.raw_safe_to_spend_paise).to eq(35_000_00)
    expect(result.safe_to_spend_paise).to eq(35_000_00)
  end

  it "returns zero when overcommitted" do
    create(:income, user: user, amount_paise: 10_000_00, occurred_on: Date.new(2026, 9, 1))
    create(:expense, user: user, amount_paise: 50_000_00, occurred_on: Date.new(2026, 9, 5))

    result = described_class.new(user, month: month).call
    expect(result.raw_safe_to_spend_paise).to be_negative
    expect(result.safe_to_spend_paise).to eq(0)
  end

  it "skips planned contribution when an active lock covers the goal" do
    goal = create(:savings_goal, user: user, purpose: "Vacation", monthly_contribution_paise: 8_000_00, target_date: nil)
    create(:money_lock, user: user, savings_goal: goal, purpose: "Vacation", amount_paise: 8_000_00, remaining_paise: 8_000_00)
    create(:income, user: user, amount_paise: 50_000_00, occurred_on: Date.new(2026, 9, 1))

    result = described_class.new(user, month: month).call
    expect(result.planned_savings_paise).to eq(0)
    expect(result.locked_paise).to eq(8_000_00)
  end
end
