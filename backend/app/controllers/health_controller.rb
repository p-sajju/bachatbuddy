# frozen_string_literal: true

class HealthController < ActionController::API
  def show
    render json: {
      status: "ok",
      service: "bachatbuddy-api",
      time: Time.current.iso8601
    }, status: :ok
  end

  def ready
    checks = { database: database_ok?, redis: redis_status }
    ready = checks[:database]
    status = ready ? :ok : :service_unavailable
    render json: {
      status: ready ? "ready" : "not_ready",
      checks: checks
    }, status: status
  end

  private

  def database_ok?
    ActiveRecord::Base.connection_pool.with_connection do |conn|
      conn.select_value("SELECT 1") == 1
    end
  rescue StandardError
    false
  end

  def redis_status
    url = ENV["REDIS_URL"]
    return "skipped" if url.blank?

    Redis.new(url: url).ping == "PONG" ? "ok" : "error"
  rescue StandardError
    "unavailable"
  end
end
