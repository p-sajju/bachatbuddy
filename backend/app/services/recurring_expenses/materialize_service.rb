# frozen_string_literal: true

module RecurringExpenses
  class MaterializeService
    def initialize(as_of: Date.current)
      @as_of = as_of.to_date
    end

    def call(user: nil)
      scope = RecurringExpense.due_on_or_before(@as_of)
      scope = scope.where(user_id: user.id) if user
      created = 0

      scope.find_each do |rec|
        created += 1 if materialize_one!(rec)
      end

      created
    end

    def materialize_one!(rec)
      due = rec.next_occurrence_on
      return false if due > @as_of
      return false unless rec.active?

      ActiveRecord::Base.transaction do
        locked = RecurringExpense.lock.find(rec.id)
        return false if locked.next_occurrence_on > @as_of

        existing = Expense.find_by(recurring_expense_id: locked.id, occurred_on: locked.next_occurrence_on)
        if existing
          advance!(locked)
          return false
        end

        Expense.create!(
          user_id: locked.user_id,
          category_id: locked.category_id,
          payment_source_id: locked.payment_source_id,
          person_id: locked.person_id,
          recurring_expense_id: locked.id,
          amount_paise: locked.amount_paise,
          occurred_on: locked.next_occurrence_on,
          note: "Auto: #{locked.name}"
        )
        advance!(locked)
        true
      end
    rescue ActiveRecord::RecordNotUnique
      false
    end

    private

    def advance!(rec)
      next_date = case rec.frequency
                  when "weekly"
                    rec.next_occurrence_on + 7.days
                  when "yearly"
                    rec.next_occurrence_on + 1.year
                  else
                    (rec.next_occurrence_on + 1.month).change(
                      day: [ rec.day_of_month || rec.next_occurrence_on.day, 28 ].min
                    )
                  end
      rec.update!(
        last_materialized_on: rec.next_occurrence_on,
        next_occurrence_on: next_date
      )
    end
  end
end
