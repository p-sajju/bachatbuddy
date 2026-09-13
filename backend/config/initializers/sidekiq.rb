# frozen_string_literal: true

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

def redis_available?(url)
  require "redis"
  Redis.new(url: url).ping == "PONG"
rescue StandardError
  false
end

if redis_available?(redis_url)
  Sidekiq.configure_server do |config|
    config.redis = { url: redis_url }

    schedule_file = Rails.root.join("config/sidekiq.yml")
    if defined?(Sidekiq::Cron::Job) && File.exist?(schedule_file)
      raw = YAML.safe_load(
        File.read(schedule_file),
        permitted_classes: [ Symbol ],
        aliases: true
      ) || {}
      cron = raw["schedule"] || raw[:schedule] || raw["cron"] || raw[:cron]
      Sidekiq::Cron::Job.load_from_hash!(cron) if cron.present?
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: redis_url }
  end

  Rails.application.config.active_job.queue_adapter = :sidekiq unless Rails.env.test?
else
  Rails.logger&.warn("[BachatBuddy] Redis unavailable — ActiveJob falling back to :async")
  Rails.application.config.active_job.queue_adapter = :async unless Rails.env.test?
end
