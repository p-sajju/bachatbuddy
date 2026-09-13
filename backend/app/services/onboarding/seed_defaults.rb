# frozen_string_literal: true

module Onboarding
  class SeedDefaults
    DEFAULT_EXPENSE_CATEGORIES = [
      [ "Food & Dining", "🍽️" ],
      [ "Groceries", "🛒" ],
      [ "Transport", "🚌" ],
      [ "Rent / Housing", "🏠" ],
      [ "Utilities", "💡" ],
      [ "Mobile / Internet", "📱" ],
      [ "Healthcare", "💊" ],
      [ "Education", "📚" ],
      [ "Entertainment", "🎬" ],
      [ "Shopping", "🛍️" ],
      [ "Family / Parents", "👨‍👩‍👧" ],
      [ "EMI / Loans", "🏦" ],
      [ "Subscriptions", "🔁" ],
      [ "Miscellaneous", "📦" ]
    ].freeze

    DEFAULT_INCOME_CATEGORIES = [
      [ "Salary", "💼" ],
      [ "Business", "🏢" ],
      [ "Freelance", "💻" ],
      [ "Interest / Dividends", "📈" ],
      [ "Other Income", "➕" ]
    ].freeze

    DEFAULT_PAYMENT_SOURCES = [
      [ "Cash", "cash" ],
      [ "UPI", "upi" ],
      [ "Credit Card", "card" ],
      [ "Debit Card", "card" ],
      [ "Bank Account", "bank" ],
      [ "Wallet", "wallet" ]
    ].freeze

    def initialize(user)
      @user = user
    end

    def call
      DEFAULT_EXPENSE_CATEGORIES.each_with_index do |(name, icon), idx|
        @user.categories.find_or_create_by!(name: name, kind: "expense") do |c|
          c.icon = icon
          c.position = idx
          c.system = true
        end
      end

      DEFAULT_INCOME_CATEGORIES.each_with_index do |(name, icon), idx|
        @user.categories.find_or_create_by!(name: name, kind: "income") do |c|
          c.icon = icon
          c.position = idx
          c.system = true
        end
      end

      DEFAULT_PAYMENT_SOURCES.each do |name, kind|
        @user.payment_sources.find_or_create_by!(name: name) do |ps|
          ps.kind = kind
          ps.system = true
        end
      end
    end
  end
end
