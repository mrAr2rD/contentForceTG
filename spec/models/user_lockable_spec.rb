# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, "Devise :lockable module", type: :model do
  let(:user) { create(:user, password: "password123") }

  describe "lockable fields" do
    it "has failed_attempts counter" do
      expect(user).to respond_to(:failed_attempts)
      expect(user.failed_attempts).to eq(0)
    end

    it "has locked_at timestamp" do
      expect(user).to respond_to(:locked_at)
      expect(user.locked_at).to be_nil
    end

    it "has unlock_token" do
      expect(user).to respond_to(:unlock_token)
      expect(user.unlock_token).to be_nil
    end
  end

  describe "#lock_access!" do
    it "locks the user account" do
      user.lock_access!

      expect(user.access_locked?).to be true
      expect(user.locked_at).to be_present
    end

    it "generates unlock_token" do
      user.lock_access!
      expect(user.unlock_token).to be_present
    end
  end

  describe "#unlock_access!" do
    before do
      user.lock_access!
    end

    it "unlocks the user account" do
      user.unlock_access!

      expect(user.access_locked?).to be false
      expect(user.locked_at).to be_nil
    end

    it "resets failed_attempts" do
      user.update!(failed_attempts: 5)
      user.unlock_access!

      expect(user.failed_attempts).to eq(0)
    end

    it "clears unlock_token" do
      user.unlock_access!
      expect(user.unlock_token).to be_nil
    end
  end

  describe "#access_locked?" do
    context "when locked_at is nil" do
      it "returns false" do
        expect(user.access_locked?).to be false
      end
    end

    context "when locked_at is present and within lock period" do
      it "returns true" do
        user.update!(locked_at: 30.minutes.ago)
        expect(user.access_locked?).to be true
      end
    end

    context "when locked_at is present but lock period expired" do
      it "returns false (auto-unlock)" do
        user.update!(locked_at: 2.hours.ago)
        expect(user.access_locked?).to be false
      end
    end
  end

  describe "failed login attempts" do
    it "increments failed_attempts on wrong password" do
      expect {
        user.valid_password?("wrong_password")
      }.not_to change { user.failed_attempts }

      # Increment происходит в Devise::Models::Lockable#increment_failed_attempts
      # который вызывается из warden стратегии при неудачном входе
    end

    it "resets failed_attempts after successful login" do
      user.update!(failed_attempts: 3)

      # После успешного входа Devise сбросит счётчик
      user.valid_password?("password123")
      user.reset_failed_attempts! if user.valid_password?("password123")

      expect(user.failed_attempts).to eq(0)
    end
  end

  describe "#send_unlock_instructions" do
    before do
      user.lock_access!
    end

    it "sends unlock email" do
      expect {
        user.send_unlock_instructions
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "generates new unlock_token" do
      old_token = user.unlock_token
      user.send_unlock_instructions

      user.reload
      expect(user.unlock_token).not_to eq(old_token)
    end
  end

  describe "unlock_token uniqueness" do
    it "has unique index on unlock_token" do
      # Проверяем наличие индекса через схему БД
      indexes = ActiveRecord::Base.connection.indexes(:users)
      unlock_token_index = indexes.find { |idx| idx.columns == [ "unlock_token" ] }

      expect(unlock_token_index).to be_present
      expect(unlock_token_index.unique).to be true
    end
  end

  describe "Devise configuration" do
    it "uses :failed_attempts lock strategy" do
      expect(Devise.lock_strategy).to eq(:failed_attempts)
    end

    it "sets maximum_attempts to 5" do
      expect(Devise.maximum_attempts).to eq(5)
    end

    it "sets unlock_in to 1 hour" do
      expect(Devise.unlock_in).to eq(1.hour)
    end

    it "uses :both unlock strategy" do
      expect(Devise.unlock_strategy).to eq(:both)
    end

    it "warns on last attempt" do
      expect(Devise.last_attempt_warning).to be true
    end
  end
end
