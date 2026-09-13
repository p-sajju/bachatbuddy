# frozen_string_literal: true

origins = ENV.fetch("CORS_ORIGINS", "http://localhost:3001").split(",").map(&:strip).reject(&:empty?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*origins)

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: %w[X-Request-Id Authorization],
             max_age: 600
  end
end
