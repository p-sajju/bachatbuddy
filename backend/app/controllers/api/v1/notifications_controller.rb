# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :set_notification, only: %i[show update]

      def index
        scope = current_user.notifications.order(created_at: :desc)
        scope = scope.unread if params[:unread] == "true"
        records, meta = paginate(scope)
        render_success(records.map(&:as_api_json), meta: meta)
      end

      def show
        render_success(@notification.as_api_json)
      end

      def update
        @notification.mark_read! if params[:read] || params[:mark_read]
        render_success(@notification.as_api_json)
      end

      def mark_all_read
        current_user.notifications.unread.update_all(read_at: Time.current)
        render_success({ marked_all_read: true })
      end

      private

      def set_notification
        @notification = current_user.notifications.find(params[:id])
      end
    end
  end
end
