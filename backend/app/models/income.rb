# frozen_string_literal: true

class Income < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :payment_source, optional: true

  validates :amount_paise, numericality: { only_integer: true, greater_than: 0 }
  validates :occurred_on, presence: true

  scope :in_period, ->(range) { where(occurred_on: range) }

  def as_api_json
    {
      id: id,
      amount_paise: amount_paise,
      amount_formatted: Money.format_paise(amount_paise),
      occurred_on: occurred_on,
      received_on: occurred_on,
      source: note.presence || category&.name,
      note: note,
      category_id: category_id,
      payment_source_id: payment_source_id,
      category: category&.as_api_json,
      payment_source: payment_source&.as_api_json
    }
  end
end
