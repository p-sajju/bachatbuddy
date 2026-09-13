# frozen_string_literal: true

module Api
  module V1
    class ExpensesController < ApplicationController
      before_action :set_expense, only: %i[show update destroy]

      def index
        scope = current_user.expenses.includes(:category, :person, :payment_source)
                            .order(occurred_on: :desc, created_at: :desc)
        scope = scope.where(person_id: params[:person_id]) if params[:person_id].present?
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        records, meta = paginate(scope)
        render_success(records.map(&:as_api_json), meta: meta)
      end

      def show
        render_success(@expense.as_api_json)
      end

      def create
        with_idempotency do
          expense = current_user.expenses.create!(expense_params)
          render_success(expense.as_api_json, status: :created)
        end
      end

      def update
        @expense.update!(expense_params)
        render_success(@expense.as_api_json)
      end

      def destroy
        @expense.destroy!
        render_success({ deleted: true })
      end

      private

      def set_expense
        @expense = current_user.expenses.includes(:category, :person, :payment_source).find(params[:id])
      end

      def expense_params
        attrs = params.permit(
          :amount_paise, :occurred_on, :spent_on, :note,
          :category_id, :payment_source_id, :person_id
        ).to_h

        spent_on = attrs.delete("spent_on")
        attrs["occurred_on"] ||= spent_on
        attrs
      end
    end
  end
end
