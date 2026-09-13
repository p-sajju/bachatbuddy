# frozen_string_literal: true

module Api
  module V1
    class DashboardController < ApplicationController

      def show
        month = params[:month].presence
        render_success(Dashboard::Summary.new(current_user, month: month).call)
      end
    end
  end
end
