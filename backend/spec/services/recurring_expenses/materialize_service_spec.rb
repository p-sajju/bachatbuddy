# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecurringExpenses::MaterializeService do
  let(:user) { create(:user) }
  let(:as_of) { Date.new(2026, 9, 15) }

  around do |example|
    Timecop.freeze(Time.zone.parse("2026-09-15 12:00:00")) { example.run }
  end

  describe "#call" do
    it "materializes a due recurring expense into an expense once" do
      rec = create(:recurring_expense, user: user, amount_paise: 15_000_00,
                                       next_occurrence_on: Date.new(2026, 9, 1),
                                       day_of_month: 1, active: true)

      expect {
        expect(described_class.new(as_of: as_of).call(user: user)).to eq(1)
      }.to change(Expense, :count).by(1)

      expense = Expense.find_by!(recurring_expense_id: rec.id)
      expect(expense.amount_paise).to eq(15_000_00)
      expect(expense.occurred_on).to eq(Date.new(2026, 9, 1))
      expect(expense.note).to eq("Auto: #{rec.name}")
      expect(rec.reload.last_materialized_on).to eq(Date.new(2026, 9, 1))
      expect(rec.next_occurrence_on).to be > as_of
    end

    it "does not duplicate when run twice" do
      create(:recurring_expense, user: user, amount_paise: 15_000_00,
                                 next_occurrence_on: Date.new(2026, 9, 1),
                                 day_of_month: 1, active: true)

      expect(described_class.new(as_of: as_of).call(user: user)).to eq(1)
      expect {
        expect(described_class.new(as_of: as_of).call(user: user)).to eq(0)
      }.not_to change(Expense, :count)
    end

    it "skips inactive recurring expenses" do
      create(:recurring_expense, user: user, amount_paise: 15_000_00,
                                 next_occurrence_on: Date.new(2026, 9, 1),
                                 active: false)

      expect {
        expect(described_class.new(as_of: as_of).call(user: user)).to eq(0)
      }.not_to change(Expense, :count)
    end
  end

  describe "STS upcoming amounts" do
    it "includes upcoming recurring amounts in STS before materialize" do
      create(:income, user: user, amount_paise: 100_000_00, occurred_on: Date.new(2026, 9, 1))
      create(:recurring_expense, user: user, amount_paise: 12_000_00,
                                 next_occurrence_on: Date.new(2026, 9, 20),
                                 last_materialized_on: nil, active: true)

      before = SafeToSpendCalculator.new(user, month: Date.new(2026, 9, 1)).call
      expect(before.upcoming_recurring_paise).to eq(12_000_00)
      expect(before.safe_to_spend_paise).to eq(88_000_00)

      # not due yet relative to as_of Sep 15 — still counted as upcoming
      expect(described_class.new(as_of: as_of).call(user: user)).to eq(0)
      expect(Expense.count).to eq(0)

      after = SafeToSpendCalculator.new(user, month: Date.new(2026, 9, 1)).call
      expect(after.upcoming_recurring_paise).to eq(12_000_00)
    end
  end
end
