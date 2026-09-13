# frozen_string_literal: true

class MaterializeRecurringExpensesJob < ApplicationJob
  queue_as :default

  def perform(as_of = Date.current)
    RecurringExpenses::MaterializeService.new(as_of: as_of).call
  end
end
