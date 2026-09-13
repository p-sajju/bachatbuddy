# frozen_string_literal: true

Rails.application.config.filter_parameters += [
  :passw, :password, :password_confirmation,
  :email, :secret, :token, :refresh_token, :access_token,
  :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :amount_paise, :target_paise, :current_paise, :remaining_paise,
  :requested_amount_paise, :monthly_contribution_paise
]
