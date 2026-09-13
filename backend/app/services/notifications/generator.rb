# frozen_string_literal: true

module Notifications
  class Generator
    def initialize(user)
      @user = user
    end

    def call
      created = []
      created << maybe_create_low_sts!
      created << maybe_create_goal_nudge!
      created << maybe_create_cooling_off_ready!
      created.compact
    end

    def create!(kind:, title:, body:, dedupe_key:, payload: {})
      notification = @user.notifications.find_or_initialize_by(dedupe_key: dedupe_key)
      return nil if notification.persisted?

      notification.assign_attributes(kind: kind, title: title, body: body, payload: payload)
      notification.save!
      notification
    end

    private

    def maybe_create_low_sts!
      sts = SafeToSpendCalculator.new(@user).call
      return nil unless sts.safe_to_spend_paise < 5_000_00 && sts.raw_safe_to_spend_paise < 10_000_00

      month_key = Time.current.in_time_zone(@user.timezone).strftime("%Y-%m")
      create!(
        kind: "low_safe_to_spend",
        title: "Safe-to-Spend is running low",
        body: "Your planning balance is #{Money.format_paise(sts.safe_to_spend_paise)}.",
        dedupe_key: "low_sts:#{month_key}",
        payload: { safe_to_spend_paise: sts.safe_to_spend_paise }
      )
    end

    def maybe_create_goal_nudge!
      goal = @user.savings_goals.active.order(updated_at: :desc).first
      return nil unless goal

      suggested = SuggestedContribution.new(goal).call
      return nil if suggested <= 0

      month_key = Time.current.in_time_zone(@user.timezone).strftime("%Y-%m")
      create!(
        kind: "goal_contribution",
        title: "Contribute to #{goal.name}",
        body: "Suggested this month: #{Money.format_paise(suggested)}.",
        dedupe_key: "goal_nudge:#{goal.id}:#{month_key}",
        payload: { savings_goal_id: goal.id, suggested_paise: suggested }
      )
    end

    def maybe_create_cooling_off_ready!
      req = @user.money_lock_unlock_requests
                 .where(status: "cooling_off")
                 .where("cooling_off_until <= ?", Time.current)
                 .order(cooling_off_until: :asc)
                 .first
      return nil unless req

      create!(
        kind: "cooling_off_complete",
        title: "Unlock cooling-off finished",
        body: "Your unlock request is ready to complete.",
        dedupe_key: "cooling_off:#{req.id}",
        payload: { unlock_request_id: req.id, money_lock_id: req.money_lock_id }
      )
    end
  end
end
