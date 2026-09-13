# frozen_string_literal: true

class SavingsGoal < ApplicationRecord
  STATUSES = %w[active paused completed cancelled].freeze

  belongs_to :user
  has_many :money_locks, dependent: :nullify

  validates :name, presence: true
  validates :target_paise, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :current_paise, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :monthly_contribution_paise, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }

  def remaining_paise
    [ target_paise - current_paise, 0 ].max
  end

  def contribute!(amount_paise)
    raise ArgumentError, "amount must be positive" if amount_paise.to_i <= 0

    with_lock do
      self.current_paise += amount_paise.to_i
      self.status = "completed" if current_paise >= target_paise && target_paise.positive?
      save!
    end
  end

  def as_api_json
    {
      id: id,
      name: name,
      target_paise: target_paise,
      current_paise: current_paise,
      remaining_paise: remaining_paise,
      target_date: target_date,
      monthly_contribution_paise: monthly_contribution_paise,
      suggested_contribution_paise: SuggestedContribution.new(self).call,
      status: status,
      purpose: purpose,
      notes: purpose
    }
  end
end
