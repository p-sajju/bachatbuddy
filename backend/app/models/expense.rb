# frozen_string_literal: true

class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :payment_source, optional: true
  belongs_to :person, optional: true
  belongs_to :recurring_expense, optional: true

  validates :amount_paise, numericality: { only_integer: true, greater_than: 0 }
  validates :occurred_on, presence: true

  scope :in_period, ->(range) { where(occurred_on: range) }

  def as_api_json
    {
      id: id,
      amount_paise: amount_paise,
      amount_formatted: Money.format_paise(amount_paise),
      occurred_on: occurred_on,
      spent_on: occurred_on,
      note: note,
      category_id: category_id,
      payment_source_id: payment_source_id,
      person_id: person_id,
      recurring_expense_id: recurring_expense_id,
      category: category&.as_api_json,
      person: person&.as_api_json,
      payment_source: payment_source&.as_api_json
    }
  end
end
