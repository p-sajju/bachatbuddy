# frozen_string_literal: true

class Budget < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :amount_paise, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :period_month, presence: true
  validates :category_id, uniqueness: { scope: [ :user_id, :period_month ] }

  def as_api_json
    {
      id: id,
      category_id: category_id,
      amount_paise: amount_paise,
      amount_formatted: Money.format_paise(amount_paise),
      period_month: period_month
    }
  end
end
