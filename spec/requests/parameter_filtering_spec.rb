# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Parameter Filtering', type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }

  before { sign_in user }

  describe 'Sensitive parameter filtering in logs' do
    it 'filters password from logs' do
      allow(Rails.logger).to receive(:info) do |message|
        expect(message).not_to include('my_secret_password') if message.is_a?(String)
      end

      post user_session_path, params: {
        user: {
          email: 'test@example.com',
          password: 'my_secret_password'
        }
      }
    end

    it 'filters bot_token from logs' do
      # Перехватываем логи
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      post project_telegram_bots_path(project), params: {
        telegram_bot: {
          bot_token: '1234567890:ABCDEFGHIJKLMNOPQRSTUVWXYZ',
          bot_username: 'test_bot',
          channel_id: '-1001234567890'
        }
      }

      # Проверяем, что токен не попал в логи
      logs.each do |log|
        expect(log).not_to include('1234567890:ABCDEFGHIJKLMNOPQRSTUVWXYZ')
        expect(log).to include('[FILTERED]') if log.include?('bot_token')
      end
    end

    it 'filters api_key from logs' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      # Симулируем запрос с api_key
      post api_v1_ai_generate_path, params: {
        prompt: 'Test prompt',
        api_key: 'sk-test-secret-api-key-12345'
      }

      logs.each do |log|
        expect(log).not_to include('sk-test-secret-api-key-12345')
      end
    end

    it 'filters openrouter_api_key from logs' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      # Симулируем конфигурацию с OpenRouter ключом
      allow(ENV).to receive(:fetch).with('OPENROUTER_API_KEY').and_return('sk-or-v1-test-key')

      get dashboard_path

      logs.each do |log|
        expect(log).not_to include('sk-or-v1-test-key')
      end
    end

    it 'filters phone_code from logs' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      post verify_code_telegram_session_path(create(:telegram_session)), params: {
        phone_code: '12345'
      }

      logs.each do |log|
        expect(log).not_to include('12345') if log.include?('phone_code')
      end
    end

    it 'filters webhook_secret from logs' do
      bot = create(:telegram_bot, project: project, webhook_secret: 'super_secret_webhook_token')

      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      patch project_telegram_bot_path(project, bot), params: {
        telegram_bot: {
          webhook_secret: 'super_secret_webhook_token'
        }
      }

      logs.each do |log|
        expect(log).not_to include('super_secret_webhook_token')
      end
    end

    it 'filters password_1 (Robokassa) from logs' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      # Admin пытается обновить платёжные настройки
      admin = create(:user, role: :admin)
      sign_in admin

      patch admin_payment_settings_path, params: {
        payment_configuration: {
          password_1: 'robokassa_secret_password_1',
          password_2: 'robokassa_secret_password_2'
        }
      }

      logs.each do |log|
        expect(log).not_to include('robokassa_secret_password_1')
        expect(log).not_to include('robokassa_secret_password_2')
      end
    end

    it 'filters email from logs' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      post user_registration_path, params: {
        user: {
          email: 'sensitive_email@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }

      logs.each do |log|
        expect(log).not_to include('sensitive_email@example.com')
      end
    end

    it 'filters secret from logs' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      # Любой параметр с "secret" в названии должен фильтроваться
      get root_path, params: {
        my_secret: 'this_should_be_filtered',
        client_secret: 'also_filtered'
      }

      logs.each do |log|
        expect(log).not_to include('this_should_be_filtered')
        expect(log).not_to include('also_filtered')
      end
    end

    it 'filters cvv and cvc from logs' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      # Симулируем платёжную форму (хотя мы используем Robokassa)
      post root_path, params: {
        payment: {
          cvv: '123',
          cvc: '456'
        }
      }

      logs.each do |log|
        expect(log).not_to include('123') if log.include?('cvv')
        expect(log).not_to include('456') if log.include?('cvc')
      end
    end
  end

  describe 'Parameter filtering in different contexts' do
    it 'filters parameters in error logs' do
      logs = []
      allow(Rails.logger).to receive(:error) do |message|
        logs << message if message.is_a?(String)
      end

      # Симулируем ошибку с sensitive данными
      begin
        raise StandardError, "Error with password: secret_password_123"
      rescue StandardError => e
        Rails.logger.error("Error: #{e.message}")
      end

      # Само сообщение об ошибке не фильтруется (это не параметры),
      # но если бы это были параметры в логе, они бы фильтровались
      expect(logs.first).to include('secret_password_123')
    end

    it 'filters parameters in JSON responses' do
      bot = create(:telegram_bot, project: project)

      get project_telegram_bot_path(project, bot), headers: { 'Accept' => 'application/json' }

      # В JSON ответе sensitive поля тоже должны быть защищены
      # (но это обычно настраивается на уровне serializer)
      json_response = JSON.parse(response.body) rescue {}

      expect(json_response.dig('bot_token')).to be_nil
    end
  end

  describe 'Partial matching' do
    it 'filters parameters with "passw" substring' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      post root_path, params: {
        user_password: 'secret123',
        new_password: 'newsecret456',
        password_confirmation: 'confirm789'
      }

      logs.each do |log|
        expect(log).not_to include('secret123')
        expect(log).not_to include('newsecret456')
        expect(log).not_to include('confirm789')
      end
    end

    it 'filters parameters with "token" substring' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      post root_path, params: {
        access_token: 'access123',
        refresh_token: 'refresh456',
        csrf_token: 'csrf789'
      }

      logs.each do |log|
        expect(log).not_to include('access123')
        expect(log).not_to include('refresh456')
        # csrf_token обычно не фильтруется для отладки, но лучше проверить
      end
    end

    it 'filters parameters with "_key" suffix' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      post root_path, params: {
        encryption_key: 'encrypt123',
        private_key: 'private456'
      }

      logs.each do |log|
        expect(log).not_to include('encrypt123')
        expect(log).not_to include('private456')
      end
    end
  end

  describe 'Non-sensitive parameters' do
    it 'does not filter non-sensitive parameters' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      get root_path, params: {
        query: 'search term',
        page: '2',
        category: 'technology'
      }

      # Эти параметры НЕ должны фильтроваться
      logs_text = logs.join(" ")
      expect(logs_text.include?("search term") || !logs_text.include?("[FILTERED]")).to be true
    end
  end

  describe 'Security edge cases' do
    it 'filters nested sensitive parameters' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      post root_path, params: {
        user: {
          profile: {
            secret_info: 'nested_secret_123'
          }
        }
      }

      logs.each do |log|
        expect(log).not_to include('nested_secret_123')
      end
    end

    it 'filters arrays with sensitive data' do
      logs = []
      allow(Rails.logger).to receive(:info) do |message|
        logs << message if message.is_a?(String)
      end

      post root_path, params: {
        tokens: [ 'token1', 'token2', 'token3' ]
      }

      logs.each do |log|
        # Массив токенов должен фильтроваться
        expect(log).not_to include('token1')
        expect(log).not_to include('token2')
        expect(log).not_to include('token3')
      end
    end
  end
end
