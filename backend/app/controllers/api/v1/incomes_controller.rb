# frozen_string_literal: true

module Api
  module V1
    class IncomesController < ApplicationController
      before_action :set_income, only: %i[show update destroy]

      def index
        scope = current_user.incomes.includes(:category, :payment_source)
                            .order(occurred_on: :desc, created_at: :desc)
        records, meta = paginate(scope)
        render_success(records.map(&:as_api_json), meta: meta)
      end

      def show
        render_success(@income.as_api_json)
      end

      def create
        with_idempotency do
          income = current_user.incomes.create!(income_params)
          render_success(income.as_api_json, status: :created)
        end
      end

      def update
        @income.update!(income_params)
        render_success(@income.as_api_json)
      end

      def destroy
        @income.destroy!
        render_success({ deleted: true })
      end

      private

      def set_income
        @income = current_user.incomes.includes(:category, :payment_source).find(params[:id])
      end

      def income_params
        attrs = params.permit(
          :amount_paise, :occurred_on, :received_on, :note, :source,
          :category_id, :payment_source_id
        ).to_h

        received_on = attrs.delete("received_on")
        attrs["occurred_on"] ||= received_on

        source = attrs.delete("source")
        if source.present? && attrs["note"].blank?
          attrs["note"] = source
        end

        attrs
      end
    end
  end
end
