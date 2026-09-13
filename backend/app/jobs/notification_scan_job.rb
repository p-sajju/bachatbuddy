# frozen_string_literal: true

class NotificationScanJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      Notifications::Generator.new(user).call
    end
  end
end
