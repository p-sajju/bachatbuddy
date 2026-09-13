# frozen_string_literal: true

module Api
  module V1
    class ReportsController < ApplicationController

      def monthly
        month = (params[:month].presence || Time.current.in_time_zone(current_user.timezone).to_date).to_date
        render_success(Reports::Monthly.new(current_user, month: month).call)
      end

      def safe_to_spend
        month = params[:month].presence
        render_success(SafeToSpendCalculator.new(current_user, month: month).as_api_json)
      end
    end
  end
end
