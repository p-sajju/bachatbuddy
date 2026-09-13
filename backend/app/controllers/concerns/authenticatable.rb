# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  private

  def authenticate_user!
    render_error(code: "unauthorized", message: "Authentication required", status: :unauthorized) unless current_user
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = user_from_token
  end

  def user_from_token
    header = request.headers["Authorization"].to_s
    return nil unless header.start_with?("Bearer ")

    token = header.split(" ", 2).last
    payload = JwtService.decode(token)
    return nil unless payload && payload["sub"]

    User.find_by(id: payload["sub"])
  end
end
