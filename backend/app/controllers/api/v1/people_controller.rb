# frozen_string_literal: true

module Api
  module V1
    class PeopleController < ApplicationController
      before_action :set_person, only: %i[show update destroy summary]

      def index
        render_success(current_user.people.order(:name).map(&:as_api_json))
      end

      def show
        render_success(@person.as_api_json)
      end

      def create
        person = current_user.people.create!(person_params)
        render_success(person.as_api_json, status: :created)
      end

      def update
        @person.update!(person_params)
        render_success(@person.as_api_json)
      end

      def destroy
        @person.destroy!
        render_success({ deleted: true })
      end

      def summary
        month = (params[:month].presence || Time.current.in_time_zone(current_user.timezone).to_date).to_date.beginning_of_month
        range = month..month.end_of_month
        expenses = current_user.expenses.includes(:category, :payment_source)
                               .where(person_id: @person.id).in_period(range)
        by_category = expenses.where.not(category_id: nil).group(:category_id).sum(:amount_paise).map do |cid, total|
          { name: Category.find_by(id: cid)&.name || "Uncategorized", amount_paise: total }
        end.sort_by { |row| -row[:amount_paise] }

        render_success(
          @person.as_api_json.merge(
            month: month,
            by_category: by_category,
            expenses: expenses.order(occurred_on: :desc).limit(50).map(&:as_api_json)
          )
        )
      end

      private

      def set_person
        @person = current_user.people.find(params[:id])
      end

      def person_params
        attrs = params.permit(:name, :relation, :relationship, :notes).to_h
        relationship = attrs.delete("relationship")
        attrs["relation"] ||= relationship
        attrs.delete("notes") # no notes column; accept and ignore for frontend compatibility
        attrs
      end
    end
  end
end
