# frozen_string_literal: true

module MoneyLocks
  class UnlockService
    COOLING_OFF = 24.hours
    Error = Class.new(StandardError)
    Conflict = Class.new(Error)
    InvalidConfirmation = Class.new(Error)

    URGENCY_ALIASES = {
      "planned" => "normal",
      "soon" => "normal",
      "urgent" => "normal",
      "normal" => "normal",
      "emergency" => "emergency"
    }.freeze

    def initialize(user, money_lock)
      @user = user
      @lock = money_lock
    end

    def preview(requested_amount_paise:, urgency: "normal")
      amount = resolve_amount(requested_amount_paise)
      normalized = normalize_urgency(urgency)
      phrase = confirmation_phrase(amount)

      {
        lock: @lock.as_api_json,
        money_lock_id: @lock.id,
        requested_amount_paise: amount,
        remaining_after_paise: @lock.remaining_paise - amount,
        warnings: [
          "Unlocking reduces protection on money you intended to save.",
          "Normal unlocks wait through a cooling-off period.",
          "Emergency unlocks require typing UNLOCK followed by the amount."
        ],
        cooling_off_hours: COOLING_OFF / 1.hour,
        requires_confirmation_phrase: normalized == "emergency",
        confirmation_phrase: phrase,
        confirmation_phrase_example: phrase
      }
    end

    def request_unlock!(requested_amount_paise:, reason:, urgency: "normal")
      amount = resolve_amount(requested_amount_paise)
      raw_urgency = urgency.to_s
      normalized = normalize_urgency(raw_urgency)
      stored_urgency = MoneyLockUnlockRequest::URGENCIES.include?(raw_urgency) ? raw_urgency : normalized
      raise Error, "Reason is required" if reason.blank?

      ActiveRecord::Base.transaction do
        lock = MoneyLock.lock.find_by!(id: @lock.id, user_id: @user.id)
        raise Conflict, "Lock is not active" unless lock.active_like?
        raise Error, "Amount exceeds remaining" if amount <= 0 || amount > lock.remaining_paise

        if normalized == "emergency"
          req = lock.unlock_requests.create!(
            user: @user,
            requested_amount_paise: amount,
            reason: reason,
            urgency: stored_urgency,
            status: "awaiting_confirm",
            confirmation_phrase: confirmation_phrase(amount)
          )
          record_event!(lock, req, "emergency_requested", amount)
        else
          req = lock.unlock_requests.create!(
            user: @user,
            requested_amount_paise: amount,
            reason: reason,
            urgency: stored_urgency,
            status: "cooling_off",
            cooling_off_until: COOLING_OFF.from_now
          )
          lock.update!(status: "unlock_requested", unlock_at: req.cooling_off_until)
          record_event!(lock, req, "unlock_requested", amount)
          CoolingOffUnlockJob.set(wait_until: req.cooling_off_until).perform_later(req.id)
        end

        req
      end
    end

    def emergency_unlock_with_confirmation!(requested_amount_paise:, reason:, confirmation:)
      amount = resolve_amount(requested_amount_paise)
      raise Error, "Reason is required" if reason.blank?

      phrase = confirmation_phrase(amount)
      raise InvalidConfirmation, "Confirmation phrase does not match" unless phrase_matches?(confirmation, phrase)

      ActiveRecord::Base.transaction do
        lock = MoneyLock.lock.find_by!(id: @lock.id, user_id: @user.id)
        raise Conflict, "Lock is not active" unless lock.active_like?
        raise Error, "Amount exceeds remaining" if amount <= 0 || amount > lock.remaining_paise

        req = lock.unlock_requests.create!(
          user: @user,
          requested_amount_paise: amount,
          reason: reason,
          urgency: "emergency",
          status: "awaiting_confirm",
          confirmation_phrase: phrase
        )
        record_event!(lock, req, "emergency_requested", amount)
        apply_unlock!(lock, req, event_type: "emergency_unlocked")
        req
      end
    end

    def confirm_emergency!(unlock_request_id:, confirmation:)
      ActiveRecord::Base.transaction do
        lock = MoneyLock.lock.find_by!(id: @lock.id, user_id: @user.id)
        req = lock.unlock_requests.lock.find_by!(id: unlock_request_id, user_id: @user.id)
        raise Conflict, "Request is not awaiting confirmation" unless req.status == "awaiting_confirm"
        raise InvalidConfirmation, "Confirmation phrase does not match" unless phrase_matches?(confirmation, req.confirmation_phrase)

        apply_unlock!(lock, req, event_type: "emergency_unlocked")
        req
      end
    end

    def confirm_latest_emergency!(confirmation:)
      req = @lock.unlock_requests.where(status: "awaiting_confirm", urgency: "emergency")
                 .order(created_at: :desc).first
      raise Error, "No emergency unlock awaiting confirmation" unless req

      confirm_emergency!(unlock_request_id: req.id, confirmation: confirmation)
    end

    def complete_cooling_off!(unlock_request_id)
      ActiveRecord::Base.transaction do
        lock = MoneyLock.lock.find_by!(id: @lock.id, user_id: @user.id)
        req = lock.unlock_requests.lock.find_by!(id: unlock_request_id, user_id: @user.id)
        return req if req.status == "completed"
        raise Conflict, "Request is not in cooling off" unless req.status == "cooling_off"
        raise Conflict, "Cooling off not finished" if req.cooling_off_until && req.cooling_off_until > Time.current

        apply_unlock!(lock, req, event_type: "cooling_off_unlocked")
        req
      end
    end

    def history
      @lock.unlock_events.order(created_at: :desc).map(&:as_api_json)
    end

    private

    def resolve_amount(requested_amount_paise)
      amount = requested_amount_paise.nil? || requested_amount_paise.to_s.strip.empty? ?
                 @lock.remaining_paise :
                 requested_amount_paise.to_i
      raise Error, "Amount must be positive" if amount <= 0
      raise Error, "Amount exceeds remaining locked balance" if amount > @lock.remaining_paise

      amount
    end

    def normalize_urgency(urgency)
      key = urgency.to_s
      normalized = URGENCY_ALIASES[key]
      raise Error, "Invalid urgency" if normalized.nil?

      normalized
    end

    def apply_unlock!(lock, req, event_type:)
      amount = req.requested_amount_paise
      raise Error, "Insufficient remaining" if amount > lock.remaining_paise

      lock.remaining_paise -= amount
      lock.status = lock.remaining_paise.zero? ? "unlocked" : "active"
      lock.unlock_at = nil if lock.status == "active"
      lock.save!

      req.update!(status: "completed")
      record_event!(lock, req, event_type, amount)
    end

    def record_event!(lock, req, event_type, amount)
      MoneyLockUnlockEvent.create!(
        money_lock: lock,
        unlock_request: req,
        user: @user,
        event_type: event_type,
        amount_paise: amount,
        metadata: { urgency: req.urgency, reason: req.reason }
      )
    end

    def confirmation_phrase(amount_paise)
      if (amount_paise.to_i % 100).zero?
        "UNLOCK #{amount_paise.to_i / 100}"
      else
        rupees = format("%.2f", Money.paise_to_rupees(amount_paise))
        "UNLOCK #{rupees}"
      end
    end

    def phrase_matches?(provided, expected)
      normalize_phrase(provided) == normalize_phrase(expected)
    end

    def normalize_phrase(phrase)
      phrase.to_s.strip.gsub(",", "").gsub(/\s+/, " ")
    end
  end
end
