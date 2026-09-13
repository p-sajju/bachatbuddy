# frozen_string_literal: true

module Middleware
  class RequestIdHeader
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      request_id = env["action_dispatch.request_id"] || headers["X-Request-Id"]
      headers["X-Request-Id"] = request_id if request_id.present?
      [ status, headers, body ]
    end
  end
end
