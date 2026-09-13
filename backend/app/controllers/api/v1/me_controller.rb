# frozen_string_literal: true

module Api
  module V1
    class MeController < ApplicationController

      def show
        render_success(current_user.as_api_json)
      end

      def update
        attrs = params.permit(:name, :timezone).to_h
        settings = current_user.settings.deep_dup

        if params[:settings].present?
          settings.merge!(params.require(:settings).permit!.to_h)
        end

        if params.key?(:onboarding_completed)
          settings["onboarding_completed"] =
            ActiveModel::Type::Boolean.new.cast(params[:onboarding_completed])
        end

        attrs[:settings] = settings if settings != current_user.settings

        ActiveRecord::Base.transaction do
          current_user.update!(attrs) if attrs.present?
          create_first_income_if_provided!
        end

        render_success(current_user.reload.as_api_json)
      end

      private

      def create_first_income_if_provided!
        income_attrs = first_income_params
        return if income_attrs.blank?

        amount = income_attrs["amount_paise"].presence&.to_i
        return unless amount && amount.positive?

        occurred_on = income_attrs["occurred_on"].presence ||
                      income_attrs["received_on"].presence ||
                      Date.current

        note = income_attrs["note"].presence || income_attrs["source"].presence || "First salary (onboarding)"

        current_user.incomes.create!(
          amount_paise: amount,
          occurred_on: occurred_on,
          note: note,
          category_id: income_attrs["category_id"].presence,
          payment_source_id: income_attrs["payment_source_id"].presence
        )
      end

      def first_income_params
        if params[:first_income].present?
          params.require(:first_income).permit(
            :amount_paise, :occurred_on, :received_on, :note, :source,
            :category_id, :payment_source_id
          ).to_h
        elsif params[:amount_paise].present?
          params.permit(
            :amount_paise, :occurred_on, :received_on, :note, :source,
            :category_id, :payment_source_id
          ).to_h
        else
          {}
        end
      end
    end
  end
end
