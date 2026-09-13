# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!, only: %i[signup login refresh]

      def signup
        email = params.require(:email)
        user = Auth::Signup.new(
          email: email,
          password: params.require(:password),
          first_name: params.require(:first_name),
          last_name: params.require(:last_name),
          phone_number: params.require(:phone_number),
          timezone: params[:timezone]
        ).call
        tokens = Auth::TokenIssuer.new(user, request: request).issue_pair!
        render_success({ user: user.as_api_json }.merge(tokens), status: :created)
      rescue ActionController::ParameterMissing => e
        render_error(code: "parameter_missing", message: e.message, status: :bad_request)
      rescue ActiveRecord::RecordInvalid => e
        render_error(code: "signup_failed", message: e.record.errors.full_messages.to_sentence,
                     status: :unprocessable_entity, fields: e.record.errors.to_hash)
      end

      def login
        user = User.find_by(email: params.require(:email).to_s.downcase)
        if user&.locked?
          return render_error(code: "account_locked", message: "Account temporarily locked. Try again later.", status: :locked)
        end

        if user&.authenticate(params.require(:password))
          user.clear_failed_logins!
          tokens = Auth::TokenIssuer.new(user, request: request).issue_pair!
          render_success({ user: user.as_api_json }.merge(tokens))
        else
          user&.register_failed_login!
          render_error(code: "invalid_credentials", message: "Invalid email or password", status: :unauthorized)
        end
      end

      def refresh
        raw = params.require(:refresh_token)
        user = Auth::TokenIssuer.find_user_by_refresh(raw)
        return render_error(code: "invalid_refresh", message: "Invalid refresh token", status: :unauthorized) unless user

        tokens = Auth::TokenIssuer.new(user, request: request).rotate!(raw)
        render_success(tokens)
      rescue ActiveRecord::RecordNotFound
        render_error(code: "invalid_refresh", message: "Invalid refresh token", status: :unauthorized)
      end

      def logout
        raw = params[:refresh_token]
        issuer = Auth::TokenIssuer.new(current_user, request: request)
        if raw.present?
          issuer.revoke!(raw)
        else
          issuer.revoke_all!
        end
        render_success({ logged_out: true })
      end
    end
  end
end
