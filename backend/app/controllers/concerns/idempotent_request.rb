# frozen_string_literal: true

module IdempotentRequest
  extend ActiveSupport::Concern

  IDEMPOTENCY_TTL = 24.hours

  private

  def with_idempotency
    key = request.headers["Idempotency-Key"].presence
    return yield unless key && current_user

    digest = Digest::SHA256.hexdigest("#{request.method}:#{request.path}:#{request.raw_post}")

    record = IdempotencyKey.find_by(user_id: current_user.id, key: key)
    if record&.completed?
      if record.request_digest.present? && record.request_digest != digest
        return render_error(code: "idempotency_conflict", message: "Idempotency-Key reused with different payload", status: :conflict)
      end

      return render json: record.response_body, status: record.response_code
    end

    record ||= IdempotencyKey.create!(
      user: current_user,
      key: key,
      request_path: request.path,
      request_method: request.method,
      request_digest: digest,
      locked_at: Time.current,
      expires_at: IDEMPOTENCY_TTL.from_now
    )

    yield.tap do
      if response.successful? || response.status.in?([ 200, 201 ])
        record.update!(
          response_code: response.status,
          response_body: JSON.parse(response.body),
          request_digest: digest
        )
      end
    end
  rescue ActiveRecord::RecordNotUnique
    retry_count = (@idempotency_retries ||= 0)
    @idempotency_retries = retry_count + 1
    raise if @idempotency_retries > 2

    retry
  end
end
