# frozen_string_literal: true

class IdempotencyKey < ApplicationRecord
  belongs_to :user

  validates :key, presence: true, uniqueness: { scope: :user_id }
  validates :request_path, :request_method, :expires_at, presence: true

  def completed?
    response_code.present? && response_body.present?
  end
end
