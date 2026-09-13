# frozen_string_literal: true

module Api
  module V1
    class SavingsGoalsController < ApplicationController
      before_action :set_goal, only: %i[show update destroy contribute]

      def index
        render_success(current_user.savings_goals.order(created_at: :desc).map(&:as_api_json))
      end

      def show
        render_success(@goal.as_api_json)
      end

      def create
        goal = current_user.savings_goals.create!(goal_params)
        render_success(goal.as_api_json, status: :created)
      end

      def update
        @goal.update!(goal_params)
        render_success(@goal.as_api_json)
      end

      def destroy
        @goal.destroy!
        render_success({ deleted: true })
      end

      def contribute
        with_idempotency do
          amount = params.require(:amount_paise).to_i
          @goal.contribute!(amount)
          render_success(@goal.as_api_json)
        end
      rescue ArgumentError => e
        render_error(code: "invalid_amount", message: e.message)
      end

      private

      def set_goal
        @goal = current_user.savings_goals.find(params[:id])
      end

      def goal_params
        attrs = params.permit(
          :name, :target_paise, :current_paise, :target_date,
          :monthly_contribution_paise, :status, :purpose, :notes
        ).to_h
        notes = attrs.delete("notes")
        attrs["purpose"] ||= notes
        attrs
      end
    end
  end
end
