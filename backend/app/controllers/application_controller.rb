# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Authenticatable
  include IdempotentRequest

  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound do |_e|
    render_error(code: "not_found", message: "Resource not found", status: :not_found)
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render_error(
      code: "validation_failed",
      message: e.record.errors.full_messages.to_sentence,
      status: :unprocessable_entity,
      fields: e.record.errors.to_hash
    )
  end

  rescue_from ActionController::ParameterMissing do |e|
    render_error(code: "parameter_missing", message: e.message, status: :bad_request)
  end

  private

  def render_success(data = nil, meta: {}, status: :ok)
    render json: { data: data, meta: meta.merge(request_id: request.request_id), errors: [] }, status: status
  end

  def render_error(code:, message:, status: :unprocessable_entity, fields: nil)
    error = { code: code, message: message }
    error[:fields] = fields if fields.present?
    render json: { data: nil, meta: { request_id: request.request_id }, errors: [ error ] }, status: status
  end

  def pagination_meta(scope)
    page = [ params[:page].to_i, 1 ].max
    per_page = [[ params[:per_page].to_i, 1 ].max, 100 ].min
    per_page = 25 if params[:per_page].blank?
    total = scope.count
    {
      page: page,
      per_page: per_page,
      total: total,
      total_pages: (total.to_f / per_page).ceil
    }
  end

  def paginate(scope)
    meta = pagination_meta(scope)
    records = scope.offset((meta[:page] - 1) * meta[:per_page]).limit(meta[:per_page])
    [ records, meta ]
  end
end
