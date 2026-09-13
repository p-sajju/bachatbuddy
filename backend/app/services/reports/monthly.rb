# frozen_string_literal: true

module Reports
  class Monthly
    def initialize(user, month:)
      @user = user
      @month = month.to_date.beginning_of_month
      @range = @month..@month.end_of_month
    end

    def call
      income_paise = @user.incomes.in_period(@range).sum(:amount_paise)
      expenses_paise = @user.expenses.in_period(@range).sum(:amount_paise)

      by_category = @user.expenses.in_period(@range)
                         .where.not(category_id: nil)
                         .group(:category_id)
                         .sum(:amount_paise)
                         .map do |category_id, total|
        cat = Category.find_by(id: category_id)
        { name: cat&.name || "Uncategorized", amount_paise: total, category_id: category_id }
      end

      by_person = @user.expenses.in_period(@range)
                       .group(:person_id)
                       .sum(:amount_paise)
                       .map do |person_id, total|
        person = person_id ? Person.find_by(id: person_id) : nil
        { name: person&.name || "Myself", amount_paise: total, person_id: person_id }
      end

      {
        period: {
          start: @range.begin,
          end: @range.end,
          label: @month.strftime("%B %Y")
        },
        income_paise: income_paise,
        expenses_paise: expenses_paise,
        expense_paise: expenses_paise,
        net_paise: income_paise - expenses_paise,
        by_category: by_category.sort_by { |r| -r[:amount_paise] },
        by_person: by_person.sort_by { |r| -r[:amount_paise] },
        safe_to_spend: SafeToSpendCalculator.new(@user, month: @month).as_api_json
      }
    end
  end
end
