# frozen_string_literal: true

class Category < ApplicationRecord
  KINDS = %w[expense income].freeze

  belongs_to :user
  has_many :expenses, dependent: :nullify
  has_many :incomes, dependent: :nullify
  has_many :budgets, dependent: :destroy
  has_many :recurring_expenses, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: [ :user_id, :kind ] }
  validates :kind, inclusion: { in: KINDS }

  def as_api_json
    { id: id, name: name, kind: kind, icon: icon, position: position, system: system }
  end
end
