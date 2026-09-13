# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::Generator do
  let(:user) { create(:user) }
  let(:generator) { described_class.new(user) }

  describe "#create!" do
    it "prevents duplicate notifications via dedupe_key" do
      first = generator.create!(
        kind: "info",
        title: "Hello",
        body: "First",
        dedupe_key: "unique-key-1"
      )
      expect(first).to be_persisted

      second = generator.create!(
        kind: "info",
        title: "Hello again",
        body: "Second",
        dedupe_key: "unique-key-1"
      )
      expect(second).to be_nil
      expect(user.notifications.where(dedupe_key: "unique-key-1").count).to eq(1)
    end
  end

  describe "mark_read" do
    it "marks read via model#mark_read!" do
      notification = create(:notification, user: user, read_at: nil)
      notification.mark_read!
      expect(notification.read_at).to be_present

      previous = notification.read_at
      notification.mark_read!
      expect(notification.read_at).to eq(previous)
    end
  end

  describe "#call" do
    it "creates at most one low STS notification per month via dedupe" do
      create(:income, user: user, amount_paise: 1_000_00, occurred_on: Date.current.beginning_of_month)
      create(:expense, user: user, amount_paise: 900_00, occurred_on: Date.current)

      created = generator.call
      expect(created.compact).not_to be_empty

      expect {
        generator.call
      }.not_to change(Notification, :count)
    end
  end
end
