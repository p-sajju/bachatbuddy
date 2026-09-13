# frozen_string_literal: true

module Api
  module V1
    class BudgetsController < ApplicationController
      before_action :set_budget, only: %i[show update destroy]

      def index
        scope = current_user.budgets.order(period_month: :desc)
        scope = scope.where(period_month: params[:period_month]) if params[:period_month].present?
        render_success(scope.map(&:as_api_json))
      end

      def show
        render_success(@budget.as_api_json)
      end

      def create
        budget = current_user.budgets.create!(budget_params)
        render_success(budget.as_api_json, status: :created)
      end

      def update
        @budget.update!(budget_params)
        render_success(@budget.as_api_json)
      end

      def destroy
        @budget.destroy!
        render_success({ deleted: true })
      end

      private

      def set_budget
        @budget = current_user.budgets.find(params[:id])
      end

      def budget_params
        params.permit(:category_id, :amount_paise, :period_month)
      end
    end
  end
end
