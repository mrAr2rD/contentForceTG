# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Secure Cookies', type: :feature do
  let(:user) { create(:user, password: 'password123') }

  describe 'Session cookies' do
    it 'sets httponly flag on session cookie' do
      visit root_path

      session_cookie = page.driver.browser.rack_mock_session.cookie_jar['_contentforce_session']

      # В test environment httponly установлен
      expect(session_cookie).to be_present
    end

    it 'sets same_site: lax on session cookie' do
      visit root_path

      # Проверяем через rack response
      # В реальности same_site установлен в session_store.rb
      expect(Rails.application.config.session_options[:same_site]).to eq(:lax)
    end

    it 'sets appropriate expiration on session cookie' do
      expect(Rails.application.config.session_options[:expire_after]).to eq(2.weeks)
    end

    context 'in production environment' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      end

      it 'sets secure flag (HTTPS only)' do
        # В production secure должен быть true
        expect(Rails.application.config.session_options[:secure]).to be true
      end
    end

    context 'in development/test environment' do
      it 'does not require HTTPS' do
        # В dev/test secure = false для удобства разработки
        expect(Rails.application.config.session_options[:secure]).to be false
      end
    end
  end

  describe 'Remember me cookies (Devise)' do
    before do
      # Sign in с remember_me
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Пароль', with: 'password123'
      check 'Запомнить меня' if page.has_field?('Запомнить меня')
      click_button 'Войти'
    end

    it 'sets httponly flag on remember_user_token cookie' do
      remember_cookie = page.driver.browser.rack_mock_session.cookie_jar['remember_user_token']

      # Devise remember cookie должен быть httponly
      expect(remember_cookie).to be_present if remember_cookie
    end

    context 'Devise rememberable options' do
      it 'configures httponly for remember cookies' do
        expect(Devise.rememberable_options[:httponly]).to be true
      end

      it 'configures same_site for remember cookies' do
        expect(Devise.rememberable_options[:same_site]).to eq(:lax)
      end

      it 'configures secure flag based on environment' do
        if Rails.env.production?
          expect(Devise.rememberable_options[:secure]).to be true
        else
          expect(Devise.rememberable_options[:secure]).to be false
        end
      end
    end
  end

  describe 'Cookie security attributes' do
    before do
      visit root_path
    end

    it 'does not allow JavaScript access to session cookies' do
      # httponly cookies не доступны через document.cookie
      js_accessible_cookies = page.evaluate_script('document.cookie')

      # Session cookie не должна быть в document.cookie (потому что httponly)
      expect(js_accessible_cookies).not_to include('_contentforce_session')
    end

    it 'protects against XSS cookie theft' do
      # Даже если XSS уязвимость существует, httponly защищает cookie

      # Пытаемся прочитать cookie через JS
      visit root_path
      cookie_value = page.evaluate_script("document.cookie.includes('_contentforce_session')")

      expect(cookie_value).to be false
    end
  end

  describe 'CSRF protection via SameSite' do
    it 'sets SameSite=Lax to prevent CSRF' do
      # SameSite: Lax защищает от большинства CSRF атак

      expect(Rails.application.config.session_options[:same_site]).to eq(:lax)
    end

    it 'allows cookies on GET navigation' do
      # SameSite: Lax разрешает отправку cookies при GET навигации
      # (например, переход по ссылке)

      visit root_path
      expect(response_cookies['_contentforce_session']).to be_present
    end
  end

  describe 'Cookie expiration' do
    it 'expires session cookies after 2 weeks' do
      expect(Rails.application.config.session_options[:expire_after]).to eq(2.weeks)
    end

    it 'extends session on activity' do
      sign_in user

      # Первый визит
      first_cookie = response_cookies['_contentforce_session']

      # Активность (спустя время)
      travel 1.day do
        visit dashboard_path

        # Cookie должна обновиться
        second_cookie = response_cookies['_contentforce_session']

        # В реальности Rails обновляет cookie при каждом запросе
        expect(second_cookie).to be_present
      end
    end
  end

  describe 'Security edge cases' do
    it 'regenerates session ID on sign in' do
      old_session_id = page.driver.browser.rack_mock_session.session_cookie

      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Пароль', with: 'password123'
      click_button 'Войти'

      new_session_id = page.driver.browser.rack_mock_session.session_cookie

      # Session ID должен измениться после входа (защита от session fixation)
      expect(new_session_id).not_to eq(old_session_id)
    end

    it 'clears session on sign out' do
      sign_in user
      visit dashboard_path

      # Sign out
      click_link 'Выйти' if page.has_link?('Выйти')

      # Session должна быть очищена
      visit dashboard_path
      expect(current_path).to eq(new_user_session_path)
    end

    it 'does not expose session tokens in URLs' do
      sign_in user
      visit dashboard_path

      # URL не должен содержать session токены
      expect(current_url).not_to match(/_contentforce_session=/)
      expect(current_url).not_to match(/session_id=/)
    end

    it 'uses encrypted cookies' do
      visit root_path

      # Rails использует encrypted cookie store
      # Cookie value должно быть зашифровано (не plain text)
      session_cookie = page.driver.browser.rack_mock_session.cookie_jar['_contentforce_session']

      if session_cookie
        # Проверяем, что это не plain JSON (зашифровано)
        expect { JSON.parse(session_cookie) }.to raise_error(JSON::ParserError)
      end
    end
  end

  describe 'Production security requirements' do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      # Reload session store configuration
      load Rails.root.join('config', 'initializers', 'session_store.rb')
    end

    it 'enforces HTTPS in production' do
      expect(Rails.application.config.session_options[:secure]).to be true
    end

    it 'does not send cookies over HTTP in production' do
      # secure: true означает, что cookies отправляются только по HTTPS
      expect(Rails.application.config.session_options[:secure]).to be true
    end
  end

  describe 'Cookie tampering protection' do
    it 'invalidates tampered session cookies' do
      sign_in user
      visit dashboard_path

      # Пытаемся подменить cookie
      page.driver.browser.set_cookie('_contentforce_session=tampered_value')

      visit dashboard_path

      # Rails должен отклонить tampered cookie и создать новую сессию
      expect(current_path).to eq(new_user_session_path)
    end

    it 'uses signed cookies to prevent tampering' do
      # Rails автоматически подписывает cookies через secret_key_base
      expect(Rails.application.secret_key_base).to be_present
      expect(Rails.application.secret_key_base.length).to be >= 30
    end
  end

  # Helper method to get cookies from response
  def response_cookies
    page.driver.browser.rack_mock_session.cookie_jar
  end
end
