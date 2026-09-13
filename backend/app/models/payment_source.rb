# frozen_string_literal: true

class PaymentSource < ApplicationRecord
  KINDS = %w[cash upi card bank wallet other].freeze

  belongs_to :user
  has_many :expenses, dependent: :nullify
  has_many :incomes, dependent: :nullify
  has_many :recurring_expenses, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :kind, inclusion: { in: KINDS }

  def as_api_json
    { id: id, name: name, kind: kind, system: system }
  end
end
