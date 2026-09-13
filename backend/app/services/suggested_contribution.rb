# frozen_string_literal: true

class SuggestedContribution
  def initialize(goal, as_of: Time.current)
    @goal = goal
    @as_of = as_of.in_time_zone(goal.user.timezone)
  end

  def call
    remaining = [ @goal.target_paise - @goal.current_paise, 0 ].max
    return 0 if remaining.zero?

    if @goal.target_date.present?
      months = months_remaining
      return remaining if months <= 1

      Money.ceil_div(remaining, months)
    else
      @goal.monthly_contribution_paise.to_i
    end
  end

  private

  def months_remaining
    target = @goal.target_date
    today = @as_of.to_date
    return 1 if target <= today

    ((target.year * 12 + target.month) - (today.year * 12 + today.month)).clamp(1, 1200)
  end
end
