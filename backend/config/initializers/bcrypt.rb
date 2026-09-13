# frozen_string_literal: true

BCrypt::Engine.cost = ENV.fetch("BCRYPT_COST", 12).to_i
