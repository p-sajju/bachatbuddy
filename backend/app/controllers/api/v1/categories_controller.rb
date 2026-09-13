# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :set_category, only: %i[show update destroy]

      def index
        scope = current_user.categories.order(:position, :name)
        scope = scope.where(kind: params[:kind]) if params[:kind].present?
        render_success(scope.map(&:as_api_json))
      end

      def show
        render_success(@category.as_api_json)
      end

      def create
        category = current_user.categories.create!(category_params)
        render_success(category.as_api_json, status: :created)
      end

      def update
        @category.update!(category_params.except(:system))
        render_success(@category.as_api_json)
      end

      def destroy
        return render_error(code: "forbidden", message: "System categories cannot be deleted", status: :forbidden) if @category.system?

        @category.destroy!
        render_success({ deleted: true })
      end

      private

      def set_category
        @category = current_user.categories.find(params[:id])
      end

      def category_params
        params.permit(:name, :kind, :icon, :position)
      end
    end
  end
end
