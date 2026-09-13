# frozen_string_literal: true

module Dashboard
  class Summary
    DISCLAIMER = "Safe-to-Spend is a BachatBuddy planning figure, not a live bank balance."

    def initialize(user, month: nil)
      @user = user
      @month = month
    end

    def call
      sts = SafeToSpendCalculator.new(@user, month: @month)
      breakdown = sts.call
      range = breakdown.period_start..breakdown.period_end

      top_spending = @user.expenses.in_period(range)
                          .where.not(category_id: nil)
                          .group(:category_id)
                          .sum(:amount_paise)
                          .map do |category_id, total|
        cat = Category.find_by(id: category_id)
        { category_id: category_id, name: cat&.name || "Uncategorized", amount_paise: total }
      end.sort_by { |row| -row[:amount_paise] }.first(5)

      protected_locks = @user.money_locks.counting_toward_sts.order(created_at: :desc).map(&:as_api_json)
      goals = @user.savings_goals.active.order(created_at: :desc).map(&:as_api_json)
      saved_paise = @user.savings_goals.sum(:current_paise)

      {
        safe_to_spend_paise: breakdown.safe_to_spend_paise,
        income_paise: breakdown.income_paise,
        expenses_paise: breakdown.expense_paise,
        locked_paise: breakdown.locked_paise,
        saved_paise: saved_paise,
        period: { start: breakdown.period_start, end: breakdown.period_end },
        breakdown: {
          income_paise: breakdown.income_paise,
          expense_paise: breakdown.expense_paise,
          locked_paise: breakdown.locked_paise,
          upcoming_recurring_paise: breakdown.upcoming_recurring_paise,
          planned_savings_paise: breakdown.planned_savings_paise,
          raw_safe_to_spend_paise: breakdown.raw_safe_to_spend_paise
        },
        top_spending: top_spending,
        protected_locks: protected_locks,
        goals: goals,
        disclaimer: DISCLAIMER,
        insights: Insights::RuleBased.new(@user, month: @month).call,
        # retained for older clients
        safe_to_spend: sts.as_api_json,
        unread_notifications_count: @user.notifications.unread.count
      }
    end
  end
end
