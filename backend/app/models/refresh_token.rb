# frozen_string_literal: true

class RefreshToken < ApplicationRecord
  belongs_to :user
  belongs_to :replaced_by, class_name: "RefreshToken", optional: true

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def usable?
    !revoked? && !expired?
  end
end
