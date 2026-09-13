# frozen_string_literal: true

class RecurringExpense < ApplicationRecord
  FREQUENCIES = %w[monthly weekly yearly].freeze

  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :payment_source, optional: true
  belongs_to :person, optional: true
  has_many :expenses, dependent: :nullify

  validates :name, presence: true
  validates :amount_paise, numericality: { only_integer: true, greater_than: 0 }
  validates :frequency, inclusion: { in: FREQUENCIES }
  validates :next_occurrence_on, presence: true

  scope :due_on_or_before, ->(date) { where(active: true).where("next_occurrence_on <= ?", date) }

  def as_api_json
    {
      id: id,
      name: name,
      amount_paise: amount_paise,
      amount_formatted: Money.format_paise(amount_paise),
      frequency: frequency,
      cadence: frequency,
      day_of_month: day_of_month,
      day_of_week: day_of_week,
      next_occurrence_on: next_occurrence_on,
      next_due_on: next_occurrence_on,
      last_materialized_on: last_materialized_on,
      active: active,
      category_id: category_id,
      payment_source_id: payment_source_id,
      person_id: person_id,
      category: category&.as_api_json,
      person: person&.as_api_json
    }
  end
end
