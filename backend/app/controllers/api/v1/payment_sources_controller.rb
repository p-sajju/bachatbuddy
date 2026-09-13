# frozen_string_literal: true

module Api
  module V1
    class PaymentSourcesController < ApplicationController
      before_action :set_payment_source, only: %i[show update destroy]

      def index
        render_success(current_user.payment_sources.order(:name).map(&:as_api_json))
      end

      def show
        render_success(@payment_source.as_api_json)
      end

      def create
        source = current_user.payment_sources.create!(payment_source_params)
        render_success(source.as_api_json, status: :created)
      end

      def update
        @payment_source.update!(payment_source_params)
        render_success(@payment_source.as_api_json)
      end

      def destroy
        return render_error(code: "forbidden", message: "System payment sources cannot be deleted", status: :forbidden) if @payment_source.system?

        @payment_source.destroy!
        render_success({ deleted: true })
      end

      private

      def set_payment_source
        @payment_source = current_user.payment_sources.find(params[:id])
      end

      def payment_source_params
        params.permit(:name, :kind)
      end
    end
  end
end
