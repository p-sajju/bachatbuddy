# frozen_string_literal: true

class Person < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :nullify
  has_many :recurring_expenses, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :user_id }

  def as_api_json
    {
      id: id,
      name: name,
      relation: relation,
      relationship: relation,
      notes: nil,
      total_spent_paise: expenses.sum(:amount_paise)
    }
  end
end
