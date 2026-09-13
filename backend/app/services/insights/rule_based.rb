# frozen_string_literal: true

module Insights
  class RuleBased
    def initialize(user, month: nil)
      @user = user
      @sts = SafeToSpendCalculator.new(user, month: month)
    end

    def call
      breakdown = @sts.call
      insights = []

      if breakdown.safe_to_spend_paise.zero? && breakdown.raw_safe_to_spend_paise.negative?
        insights << {
          kind: "overcommitted",
          title: "You are overcommitted this month",
          body: "Expenses, locks, and planned savings exceed income. Review locks or discretionary spend."
        }
      end

      if breakdown.locked_paise.positive?
        insights << {
          kind: "locks_active",
          title: "Money locks are protecting your savings",
          body: "#{Money.format_paise(breakdown.locked_paise)} is currently locked in BachatBuddy."
        }
      end

      top_category = top_expense_category(breakdown.period_start..breakdown.period_end)
      if top_category
        insights << {
          kind: "top_category",
          title: "Top spend: #{top_category[:name]}",
          body: "#{Money.format_paise(top_category[:total])} this month."
        }
      end

      if breakdown.planned_savings_paise.positive?
        insights << {
          kind: "savings_plan",
          title: "Stay on track with planned savings",
          body: "Plan for #{Money.format_paise(breakdown.planned_savings_paise)} toward goals this month."
        }
      end

      insights
    end

    private

    def top_expense_category(range)
      row = @user.expenses.in_period(range)
                 .where.not(category_id: nil)
                 .group(:category_id)
                 .order(Arel.sql("SUM(amount_paise) DESC"))
                 .limit(1)
                 .pluck(:category_id, Arel.sql("SUM(amount_paise)"))
                 .first
      return nil unless row

      category = Category.find_by(id: row[0])
      return nil unless category

      { name: category.name, total: row[1].to_i }
    end
  end
end
