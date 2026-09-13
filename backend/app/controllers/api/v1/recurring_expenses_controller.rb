# frozen_string_literal: true

module Api
  module V1
    class RecurringExpensesController < ApplicationController
      before_action :set_recurring, only: %i[show update destroy]

      def index
        render_success(
          current_user.recurring_expenses.includes(:category, :person)
                      .order(:next_occurrence_on).map(&:as_api_json)
        )
      end

      def show
        render_success(@recurring.as_api_json)
      end

      def create
        rec = current_user.recurring_expenses.create!(recurring_params)
        render_success(rec.as_api_json, status: :created)
      end

      def update
        @recurring.update!(recurring_params)
        render_success(@recurring.as_api_json)
      end

      def destroy
        @recurring.update!(active: false)
        render_success(@recurring.as_api_json)
      end

      private

      def set_recurring
        @recurring = current_user.recurring_expenses.includes(:category, :person).find(params[:id])
      end

      def recurring_params
        attrs = params.permit(
          :name, :amount_paise, :frequency, :cadence, :day_of_month, :day_of_week,
          :next_occurrence_on, :next_due_on, :active, :category_id, :payment_source_id, :person_id
        ).to_h

        cadence = attrs.delete("cadence")
        attrs["frequency"] ||= cadence
        next_due = attrs.delete("next_due_on")
        attrs["next_occurrence_on"] ||= next_due
        attrs["next_occurrence_on"] ||= Date.current if action_name == "create"
        attrs
      end
    end
  end
end
