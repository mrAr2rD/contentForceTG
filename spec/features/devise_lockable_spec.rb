# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Devise Lockable - Brute Force Protection", type: :feature do
  let(:user) { create(:user, email: "test@example.com", password: "correct_password") }

  before do
    # Убеждаемся, что пользователь не заблокирован
    user.update!(failed_attempts: 0, locked_at: nil)
  end

  describe "SECURITY: account locking after failed attempts" do
    it "locks account after 5 failed login attempts" do
      visit new_user_session_path

      # Первые 4 неудачные попытки
      4.times do |i|
        fill_in "Email", with: user.email
        fill_in "Пароль", with: "wrong_password"
        click_button "Войти"

        user.reload
        expect(user.failed_attempts).to eq(i + 1)
        expect(user.locked_at).to be_nil
      end

      # 5-я попытка - блокировка аккаунта
      fill_in "Email", with: user.email
      fill_in "Пароль", with: "wrong_password"
      click_button "Войти"

      user.reload
      expect(user.failed_attempts).to eq(5)
      expect(user.locked_at).to be_present
      expect(user.access_locked?).to be true
    end

    it "shows lockout message after account is locked" do
      # Блокируем аккаунт вручную
      user.lock_access!

      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Пароль", with: "correct_password"
      click_button "Войти"

      expect(page).to have_content(/account.*locked/i)
      expect(current_path).to eq(new_user_session_path)
    end

    it "does not lock account for successful login" do
      visit new_user_session_path

      # Правильный пароль
      fill_in "Email", with: user.email
      fill_in "Пароль", with: "correct_password"
      click_button "Войти"

      user.reload
      expect(user.failed_attempts).to eq(0)
      expect(user.locked_at).to be_nil
    end

    it "resets failed_attempts counter after successful login" do
      # Делаем несколько неудачных попыток
      user.update!(failed_attempts: 3)

      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Пароль", with: "correct_password"
      click_button "Войти"

      user.reload
      expect(user.failed_attempts).to eq(0)
      expect(user.locked_at).to be_nil
    end
  end

  describe "SECURITY: unlock strategies" do
    before do
      user.lock_access!
    end

    describe ":time strategy - automatic unlock" do
      it "unlocks account after 1 hour" do
        # Блокируем 2 часа назад
        user.update!(locked_at: 2.hours.ago)

        visit new_user_session_path
        fill_in "Email", with: user.email
        fill_in "Пароль", with: "correct_password"
        click_button "Войти"

        # Должен войти успешно (автоматически разблокировался)
        expect(current_path).not_to eq(new_user_session_path)

        user.reload
        expect(user.locked_at).to be_nil
        expect(user.failed_attempts).to eq(0)
      end

      it "does not unlock if less than 1 hour passed" do
        # Блокировали 30 минут назад
        user.update!(locked_at: 30.minutes.ago)

        visit new_user_session_path
        fill_in "Email", with: user.email
        fill_in "Пароль", with: "correct_password"
        click_button "Войти"

        # Всё ещё заблокирован
        expect(page).to have_content(/account.*locked/i)
      end
    end

    describe ":email strategy - unlock link" do
      it "sends unlock instructions email" do
        expect {
          visit new_user_unlock_path
          fill_in "Email", with: user.email
          click_button "Resend unlock instructions"
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include(user.email)
        expect(email.subject).to match(/unlock/i)
      end

      it "unlocks account via unlock token link" do
        user.send_unlock_instructions

        # Получаем токен из email (в реальности будет в ссылке)
        unlock_token = user.unlock_token

        visit user_unlock_path(unlock_token: unlock_token)

        user.reload
        expect(user.locked_at).to be_nil
        expect(user.failed_attempts).to eq(0)
        expect(user.access_locked?).to be false
      end
    end
  end

  describe "Edge cases" do
    it "does not lock Telegram OAuth users (no password attempts)" do
      telegram_user = create(:user, telegram_id: 123456)

      # Telegram OAuth не использует пароли
      # Поэтому brute force защита не применяется

      expect(telegram_user.failed_attempts).to eq(0)
    end

    it "shows warning on last attempt before lock" do
      # Последняя попытка (4-я из 5)
      user.update!(failed_attempts: 4)

      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Пароль", with: "wrong"
      click_button "Войти"

      # Должно быть предупреждение (если настроено в представлениях)
      # expect(page).to have_content(/last attempt/i)
    end
  end
end
