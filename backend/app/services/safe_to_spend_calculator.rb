# frozen_string_literal: true

class SafeToSpendCalculator
  Breakdown = Struct.new(
    :income_paise,
    :expense_paise,
    :locked_paise,
    :upcoming_recurring_paise,
    :planned_savings_paise,
    :raw_safe_to_spend_paise,
    :safe_to_spend_paise,
    :period_start,
    :period_end,
    keyword_init: true
  )

  def initialize(user, month: nil)
    @user = user
    @tz = ActiveSupport::TimeZone[@user.timezone] || ActiveSupport::TimeZone["Asia/Kolkata"]
    @month = month || @tz.now.to_date.beginning_of_month
  end

  def call
    range = period_range
    income = @user.incomes.in_period(range).sum(:amount_paise)
    expense = @user.expenses.in_period(range).sum(:amount_paise)
    locked = @user.money_locks.counting_toward_sts.sum(:remaining_paise)
    upcoming = upcoming_recurring_paise(range)
    planned = planned_savings_paise
    raw = income - expense - locked - upcoming - planned
    safe = [ raw, 0 ].max

    Breakdown.new(
      income_paise: income,
      expense_paise: expense,
      locked_paise: locked,
      upcoming_recurring_paise: upcoming,
      planned_savings_paise: planned,
      raw_safe_to_spend_paise: raw,
      safe_to_spend_paise: safe,
      period_start: range.begin,
      period_end: range.end
    )
  end

  def as_api_json
    b = call
    {
      safe_to_spend_paise: b.safe_to_spend_paise,
      safe_to_spend_formatted: Money.format_paise(b.safe_to_spend_paise),
      disclaimer: "Safe-to-Spend is a BachatBuddy planning figure, not a live bank balance.",
      breakdown: {
        income_paise: b.income_paise,
        expense_paise: b.expense_paise,
        locked_paise: b.locked_paise,
        upcoming_recurring_paise: b.upcoming_recurring_paise,
        planned_savings_paise: b.planned_savings_paise,
        raw_safe_to_spend_paise: b.raw_safe_to_spend_paise,
        period_start: b.period_start,
        period_end: b.period_end
      }
    }
  end

  private

  def period_range
    start_date = @month.to_date.beginning_of_month
    end_date = start_date.end_of_month
    start_date..end_date
  end

  def upcoming_recurring_paise(range)
    @user.recurring_expenses.where(active: true).sum do |rec|
      due = rec.next_occurrence_on
      next 0 unless due && due >= range.begin && due <= range.end
      next 0 if rec.last_materialized_on == due
      next 0 if @user.expenses.exists?(recurring_expense_id: rec.id, occurred_on: due)

      rec.amount_paise
    end
  end

  def planned_savings_paise
    locked_purposes = @user.money_locks.counting_toward_sts
                           .where.not(purpose: [ nil, "" ])
                           .pluck(:purpose)
                           .map { |p| p.to_s.downcase }

    locked_goal_ids = @user.money_locks.counting_toward_sts.where.not(savings_goal_id: nil).pluck(:savings_goal_id)

    @user.savings_goals.active.sum do |goal|
      next 0 if locked_goal_ids.include?(goal.id)
      next 0 if goal.purpose.present? && locked_purposes.include?(goal.purpose.to_s.downcase)

      SuggestedContribution.new(goal).call
    end
  end
end
