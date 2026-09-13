# frozen_string_literal: true

module Auth
  class Signup
    def initialize(email:, password:, first_name:, last_name:, phone_number:, timezone: "Asia/Kolkata")
      @email = email
      @password = password
      @first_name = first_name
      @last_name = last_name
      @phone_number = phone_number
      @timezone = timezone.presence || "Asia/Kolkata"
    end

    def call
      user = nil
      ActiveRecord::Base.transaction do
        user = User.create!(
          email: @email,
          password: @password,
          first_name: @first_name,
          last_name: @last_name,
          phone_number: @phone_number,
          timezone: @timezone,
          settings: { "onboarding_completed" => false }
        )
        Onboarding::SeedDefaults.new(user).call
      end
      user
    end
  end
end
