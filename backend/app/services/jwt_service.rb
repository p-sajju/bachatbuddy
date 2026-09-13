# frozen_string_literal: true

class JwtService
  ALGORITHM = "HS256"

  class << self
    def encode(expires_in: nil, **payload)
      now = Time.current.to_i
      ttl = expires_in.nil? ? access_ttl : expires_in.to_i
      body = payload.merge(
        iat: now,
        exp: now + ttl,
        iss: "bachatbuddy"
      )
      JWT.encode(body, secret, ALGORITHM)
    end

    def decode(token)
      JWT.decode(token, secret, true, algorithm: ALGORITHM, iss: "bachatbuddy", verify_iss: true).first
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::InvalidIssuerError
      nil
    end

    def access_ttl
      ENV.fetch("JWT_ACCESS_TTL_SECONDS", 900).to_i
    end

    def refresh_ttl
      ENV.fetch("JWT_REFRESH_TTL_SECONDS", 2_592_000).to_i
    end

    def secret
      ENV.fetch("JWT_SECRET") do
        raise "JWT_SECRET is not configured" if Rails.env.production?

        "local-dev-jwt-secret-change-me"
      end
    end
  end
end
