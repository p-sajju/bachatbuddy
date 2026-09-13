# frozen_string_literal: true

module AuthHelpers
  def auth_headers_for(user)
    token = JwtService.encode(sub: user.id, email: user.email)
    { "Authorization" => "Bearer #{token}" }
  end

  def json_body
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
