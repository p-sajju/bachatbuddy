# frozen_string_literal: true

require Rails.root.join("lib/middleware/request_id_header")

# Ensure X-Request-Id is present on every response.
Rails.application.config.middleware.insert_after ActionDispatch::RequestId, Middleware::RequestIdHeader
