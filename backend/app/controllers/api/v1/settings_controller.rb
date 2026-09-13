# frozen_string_literal: true

module Api
  module V1
    class SettingsController < ApplicationController

      def show
        render_success(
          current_user.as_api_json.merge(
            timezone: current_user.timezone,
            settings: current_user.settings,
            safe_to_spend_disclaimer: "Safe-to-Spend is a BachatBuddy planning figure, not a live bank balance."
          )
        )
      end

      def update
        attrs = {}
        attrs[:name] = params[:name] if params.key?(:name)
        attrs[:timezone] = params[:timezone] if params.key?(:timezone)
        if params.key?(:settings)
          attrs[:settings] = current_user.settings.merge(params[:settings].permit!.to_h)
        end
        current_user.update!(attrs) if attrs.present?
        render_success(current_user.as_api_json)
      end
    end
  end
end
