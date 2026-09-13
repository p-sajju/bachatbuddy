# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user

  validates :kind, :title, :dedupe_key, presence: true
  validates :dedupe_key, uniqueness: { scope: :user_id }

  scope :unread, -> { where(read_at: nil) }

  def mark_read!
    update!(read_at: Time.current) if read_at.nil?
  end

  def as_api_json
    {
      id: id,
      kind: kind,
      title: title,
      body: body,
      read_at: read_at,
      dedupe_key: dedupe_key,
      payload: payload,
      created_at: created_at
    }
  end
end
