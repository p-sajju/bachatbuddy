# frozen_string_literal: true

module Auth
  class TokenIssuer
    def initialize(user, request: nil)
      @user = user
      @request = request
    end

    def issue_pair!
      access_token = JwtService.encode(sub: @user.id, email: @user.email)
      raw_refresh, record = create_refresh_token!
      {
        access_token: access_token,
        refresh_token: raw_refresh,
        token_type: "Bearer",
        expires_in: JwtService.access_ttl,
        refresh_token_id: record.id
      }
    end

    def rotate!(raw_refresh)
      digest = self.class.digest(raw_refresh)
      existing = @user.refresh_tokens.active.find_by(token_digest: digest)
      raise ActiveRecord::RecordNotFound, "Invalid refresh token" unless existing&.usable?

      ActiveRecord::Base.transaction do
        existing.update!(revoked_at: Time.current)
        tokens = issue_pair!
        existing.update!(replaced_by_id: tokens[:refresh_token_id])
        tokens
      end
    end

    def revoke!(raw_refresh)
      digest = self.class.digest(raw_refresh)
      token = @user.refresh_tokens.find_by(token_digest: digest)
      token&.update!(revoked_at: Time.current)
    end

    def revoke_all!
      @user.refresh_tokens.active.update_all(revoked_at: Time.current)
    end

    def self.digest(raw)
      Digest::SHA256.hexdigest(raw.to_s)
    end

    def self.find_user_by_refresh(raw)
      digest = digest(raw)
      RefreshToken.active.includes(:user).find_by(token_digest: digest)&.user
    end

    private

    def create_refresh_token!
      raw = SecureRandom.urlsafe_base64(64)
      record = @user.refresh_tokens.create!(
        token_digest: self.class.digest(raw),
        expires_at: JwtService.refresh_ttl.seconds.from_now,
        user_agent: @request&.user_agent,
        ip: @request&.remote_ip
      )
      [ raw, record ]
    end
  end
end
