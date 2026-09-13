# frozen_string_literal: true

module Auth
  class Signup
    def initialize(email:, password:, name:, timezone: "Asia/Kolkata")
      @email = email
      @password = password
      @name = name
      @timezone = timezone.presence || "Asia/Kolkata"
    end

    def call
      user = nil
      ActiveRecord::Base.transaction do
        user = User.create!(
          email: @email,
          password: @password,
          name: @name,
          timezone: @timezone,
          settings: { "onboarding_completed" => false }
        )
        Onboarding::SeedDefaults.new(user).call
      end
      user
    end
  end
end
