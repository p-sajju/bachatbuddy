# frozen_string_literal: true

class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  throttle("auth/login", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/login" && req.post?
  end

  throttle("auth/signup", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/signup" && req.post?
  end

  throttle("auth/refresh", limit: 30, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/refresh" && req.post?
  end

  self.throttled_responder = lambda do |_request|
    [
      429,
      { "Content-Type" => "application/json" },
      [ {
        data: nil,
        meta: {},
        errors: [ { code: "rate_limited", message: "Too many requests. Please try again later." } ]
      }.to_json ]
    ]
  end
end

Rails.application.config.middleware.use Rack::Attack

Rack::Attack.enabled = false if Rails.env.test?
