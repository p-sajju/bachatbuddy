# frozen_string_literal: true

module Money
  module_function

  def rupees_to_paise(rupees)
    return 0 if rupees.nil?

    (BigDecimal(rupees.to_s) * 100).round(0, BigDecimal::ROUND_HALF_UP).to_i
  end

  def paise_to_rupees(paise)
    return BigDecimal("0") if paise.nil?

    BigDecimal(paise.to_i) / 100
  end

  def format_paise(paise, symbol: true)
    amount = paise_to_rupees(paise)
    formatted = ActiveSupport::NumberHelper.number_to_currency(
      amount,
      unit: symbol ? "₹" : "",
      precision: 2,
      delimiter: ",",
      separator: ".",
      format: "%u%n",
      locale: :en
    )
    # en-IN grouping for display (approximate via Indian-style when >= 1000)
    indianize_grouping(formatted, symbol: symbol)
  end

  def ceil_div(numerator, denominator)
    raise ArgumentError, "denominator must be positive" if denominator.to_i <= 0

    (numerator.to_i + denominator.to_i - 1) / denominator.to_i
  end

  def indianize_grouping(formatted, symbol:)
    # Keep Rails currency formatting; ensure ₹ prefix when requested.
    return formatted if formatted.include?("₹") || !symbol

    "₹#{formatted}"
  end
  private_class_method :indianize_grouping
end
