# frozen_string_literal: true

module UuidPrimaryKey
  extend ActiveSupport::Concern

  included do
    before_validation :ensure_uuid, on: :create
  end

  private

  def ensure_uuid
    self.id ||= SecureRandom.uuid
  end
end
