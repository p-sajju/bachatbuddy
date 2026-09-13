# frozen_string_literal: true

module Api
  module V1
    class MoneyLocksController < ApplicationController
      before_action :set_lock, only: %i[show update destroy unlock_preview unlock_request emergency_unlock confirm_unlock history]

      def index
        render_success(current_user.money_locks.order(created_at: :desc).map(&:as_api_json))
      end

      def show
        render_success(@lock.as_api_json)
      end

      def create
        with_idempotency do
          attrs = lock_params.to_h
          name = params[:name].presence
          attrs[:note] = name if name.present?
          attrs[:locked_at] ||= Time.current
          attrs[:remaining_paise] ||= attrs[:amount_paise]
          lock = current_user.money_locks.create!(attrs)
          MoneyLockUnlockEvent.create!(
            money_lock: lock,
            user: current_user,
            event_type: "locked",
            amount_paise: lock.amount_paise,
            metadata: {}
          )
          render_success(lock.as_api_json, status: :created)
        end
      end

      def update
        attrs = lock_params.except(:amount_paise, :remaining_paise).to_h
        name = params[:name].presence
        attrs[:note] = name if name.present?
        @lock.update!(attrs)
        render_success(@lock.as_api_json)
      end

      def destroy
        @lock.update!(status: "cancelled")
        render_success(@lock.as_api_json)
      end

      def unlock_preview
        service = MoneyLocks::UnlockService.new(current_user, @lock)
        urgency = params[:urgency].presence || "normal"
        render_success(
          service.preview(
            requested_amount_paise: requested_amount_paise,
            urgency: urgency
          )
        )
      rescue MoneyLocks::UnlockService::Error => e
        render_error(code: "unlock_preview_failed", message: e.message)
      end

      def unlock_request
        with_idempotency do
          service = MoneyLocks::UnlockService.new(current_user, @lock)
          req = service.request_unlock!(
            requested_amount_paise: requested_amount_paise,
            reason: params.require(:reason),
            urgency: params[:urgency] || "normal"
          )
          render_success(req.as_api_json, status: :created)
        end
      rescue MoneyLocks::UnlockService::Error => e
        render_error(code: "unlock_request_failed", message: e.message)
      end

      def emergency_unlock
        with_idempotency do
          service = MoneyLocks::UnlockService.new(current_user, @lock)
          amount = requested_amount_paise
          reason = params.require(:reason)

          if params[:confirmation].present?
            req = service.emergency_unlock_with_confirmation!(
              requested_amount_paise: amount,
              reason: reason,
              confirmation: params[:confirmation]
            )
            render_success({ request: req.as_api_json, lock: @lock.reload.as_api_json }, status: :created)
          else
            req = service.request_unlock!(
              requested_amount_paise: amount,
              reason: reason,
              urgency: "emergency"
            )
            render_success(req.as_api_json, status: :created)
          end
        end
      rescue MoneyLocks::UnlockService::InvalidConfirmation => e
        render_error(code: "invalid_confirmation", message: e.message, status: :unprocessable_entity)
      rescue MoneyLocks::UnlockService::Error => e
        render_error(code: "emergency_unlock_failed", message: e.message)
      end

      def confirm_unlock
        with_idempotency do
          service = MoneyLocks::UnlockService.new(current_user, @lock)
          req = if params[:unlock_request_id].present?
                  service.confirm_emergency!(
                    unlock_request_id: params[:unlock_request_id],
                    confirmation: params.require(:confirmation)
                  )
                else
                  service.confirm_latest_emergency!(confirmation: params.require(:confirmation))
                end
          render_success({ request: req.as_api_json, lock: @lock.reload.as_api_json })
        end
      rescue MoneyLocks::UnlockService::InvalidConfirmation => e
        render_error(code: "invalid_confirmation", message: e.message, status: :unprocessable_entity)
      rescue MoneyLocks::UnlockService::Error => e
        render_error(code: "confirm_unlock_failed", message: e.message)
      end

      def history
        render_success(MoneyLocks::UnlockService.new(current_user, @lock).history)
      end

      private

      def set_lock
        @lock = current_user.money_locks.find(params[:id])
      end

      def lock_params
        params.permit(:amount_paise, :remaining_paise, :purpose, :status, :note, :savings_goal_id, :expires_at, :locked_at)
      end

      def requested_amount_paise
        params[:amount_paise].presence || @lock.remaining_paise
      end
    end
  end
end
