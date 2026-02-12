# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Telegram OAuth Security', type: :request do
  let(:bot_token) { ENV.fetch('TELEGRAM_BOT_TOKEN', 'test_bot_token') }
  let(:telegram_user_id) { 123456789 }
  let(:auth_date) { Time.current.to_i }

  before do
    ENV['TELEGRAM_BOT_TOKEN'] = bot_token
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
  end

  def generate_valid_telegram_auth(user_data)
    data = {
      'id' => user_data[:id].to_s,
      'first_name' => user_data[:first_name],
      'last_name' => user_data[:last_name],
      'username' => user_data[:username],
      'photo_url' => user_data[:photo_url],
      'auth_date' => auth_date.to_s
    }

    # Генерируем правильную подпись
    data_check_arr = data.map { |k, v| "#{k}=#{v}" }.sort
    data_check_string = data_check_arr.join("\n")
    secret_key = Digest::SHA256.digest(bot_token)
    hash = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'),
      secret_key,
      data_check_string
    )
    data['hash'] = hash
    data
  end

  describe 'POST /users/auth/telegram/callback' do
    context 'with valid Telegram signature' do
      let(:valid_user_data) do
        {
          id: telegram_user_id,
          first_name: 'John',
          last_name: 'Doe',
          username: 'johndoe',
          photo_url: 'https://example.com/photo.jpg'
        }
      end

      before do
        OmniAuth.config.mock_auth[:telegram] = OmniAuth::AuthHash.new(
          provider: 'telegram',
          uid: telegram_user_id.to_s,
          info: generate_valid_telegram_auth(valid_user_data)
        )
      end

      it 'successfully authenticates user' do
        get '/users/auth/telegram/callback'

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include('Telegram')
      end

      it 'creates a new user' do
        expect {
          get '/users/auth/telegram/callback'
        }.to change(User, :count).by(1)
      end

      it 'signs in the user' do
        get '/users/auth/telegram/callback'

        expect(controller.current_user).to be_present
        expect(controller.current_user.telegram_id).to eq(telegram_user_id.to_s)
      end

      it 'sets user attributes' do
        get '/users/auth/telegram/callback'

        user = User.find_by(telegram_id: telegram_user_id.to_s)
        expect(user.first_name).to eq('John')
        expect(user.last_name).to eq('Doe')
        expect(user.telegram_username).to eq('johndoe')
      end
    end

    context 'with invalid Telegram signature' do
      let(:invalid_user_data) do
        {
          'id' => telegram_user_id.to_s,
          'first_name' => 'John',
          'last_name' => 'Doe',
          'username' => 'johndoe',
          'photo_url' => 'https://example.com/photo.jpg',
          'auth_date' => auth_date.to_s,
          'hash' => 'invalid_signature_12345'
        }
      end

      before do
        OmniAuth.config.mock_auth[:telegram] = OmniAuth::AuthHash.new(
          provider: 'telegram',
          uid: telegram_user_id.to_s,
          info: invalid_user_data
        )
      end

      it 'rejects authentication' do
        get '/users/auth/telegram/callback'

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Ошибка проверки подлинности')
      end

      it 'does not create a user' do
        expect {
          get '/users/auth/telegram/callback'
        }.not_to change(User, :count)
      end

      it 'does not sign in the user' do
        get '/users/auth/telegram/callback'

        expect(controller.current_user).to be_nil
      end

      it 'logs security error' do
        expect(Rails.logger).to receive(:error).with(/Telegram OAuth security error/)

        get '/users/auth/telegram/callback'
      end
    end

    context 'with missing signature' do
      let(:data_without_hash) do
        {
          'id' => telegram_user_id.to_s,
          'first_name' => 'John',
          'last_name' => 'Doe',
          'username' => 'johndoe',
          'auth_date' => auth_date.to_s
          # 'hash' отсутствует
        }
      end

      before do
        OmniAuth.config.mock_auth[:telegram] = OmniAuth::AuthHash.new(
          provider: 'telegram',
          uid: telegram_user_id.to_s,
          info: data_without_hash
        )
      end

      it 'rejects authentication' do
        get '/users/auth/telegram/callback'

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      it 'does not create a user' do
        expect {
          get '/users/auth/telegram/callback'
        }.not_to change(User, :count)
      end
    end

    context 'with expired auth_date' do
      let(:expired_user_data) do
        {
          id: telegram_user_id,
          first_name: 'John',
          last_name: 'Doe',
          username: 'johndoe',
          photo_url: 'https://example.com/photo.jpg'
        }
      end

      let(:expired_auth_data) do
        data = {
          'id' => expired_user_data[:id].to_s,
          'first_name' => expired_user_data[:first_name],
          'last_name' => expired_user_data[:last_name],
          'username' => expired_user_data[:username],
          'photo_url' => expired_user_data[:photo_url],
          'auth_date' => 25.hours.ago.to_i.to_s # Expired
        }

        # Генерируем правильную подпись для expired данных
        data_check_arr = data.map { |k, v| "#{k}=#{v}" }.sort
        data_check_string = data_check_arr.join("\n")
        secret_key = Digest::SHA256.digest(bot_token)
        hash = OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new('sha256'),
          secret_key,
          data_check_string
        )
        data['hash'] = hash
        data
      end

      before do
        OmniAuth.config.mock_auth[:telegram] = OmniAuth::AuthHash.new(
          provider: 'telegram',
          uid: telegram_user_id.to_s,
          info: expired_auth_data
        )
      end

      it 'rejects expired authentication' do
        get '/users/auth/telegram/callback'

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      it 'logs warning about expired data' do
        expect(Rails.logger).to receive(:warn).with(/Auth data too old/)

        get '/users/auth/telegram/callback'
      end
    end

    context 'account takeover attempt' do
      let(:attacker_data) do
        {
          id: 999999999, # Атакующий пытается выдать себя за другого пользователя
          first_name: 'Attacker',
          last_name: 'Malicious',
          username: 'attacker',
          photo_url: 'https://evil.com/photo.jpg'
        }
      end

      let(:legitimate_user_id) { 111111111 }

      before do
        # Создаём легитимного пользователя
        create(:user, telegram_id: legitimate_user_id.to_s, first_name: 'Legitimate')

        # Атакующий генерирует данные с правильной подписью для своего ID
        auth_data = generate_valid_telegram_auth(attacker_data)

        # Но затем подменяет ID на легитимного пользователя (после генерации подписи)
        auth_data['id'] = legitimate_user_id.to_s

        OmniAuth.config.mock_auth[:telegram] = OmniAuth::AuthHash.new(
          provider: 'telegram',
          uid: legitimate_user_id.to_s,
          info: auth_data
        )
      end

      it 'rejects tampered authentication data' do
        get '/users/auth/telegram/callback'

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Ошибка проверки подлинности')
      end

      it 'does not allow account takeover' do
        legitimate_user = User.find_by(telegram_id: legitimate_user_id.to_s)
        original_first_name = legitimate_user.first_name

        get '/users/auth/telegram/callback'

        legitimate_user.reload
        expect(legitimate_user.first_name).to eq(original_first_name)
        expect(legitimate_user.first_name).not_to eq('Attacker')
      end
    end

    context 'updating existing user' do
      let!(:existing_user) do
        create(:user,
               telegram_id: telegram_user_id.to_s,
               first_name: 'Old Name',
               telegram_username: 'oldusername')
      end

      let(:updated_user_data) do
        {
          id: telegram_user_id,
          first_name: 'New Name',
          last_name: 'Updated',
          username: 'newusername',
          photo_url: 'https://example.com/new_photo.jpg'
        }
      end

      before do
        OmniAuth.config.mock_auth[:telegram] = OmniAuth::AuthHash.new(
          provider: 'telegram',
          uid: telegram_user_id.to_s,
          info: generate_valid_telegram_auth(updated_user_data)
        )
      end

      it 'updates existing user data' do
        get '/users/auth/telegram/callback'

        existing_user.reload
        expect(existing_user.first_name).to eq('New Name')
        expect(existing_user.telegram_username).to eq('newusername')
      end

      it 'does not create duplicate user' do
        expect {
          get '/users/auth/telegram/callback'
        }.not_to change(User, :count)
      end
    end
  end

  describe 'Security edge cases' do
    context 'with SQL injection attempt in user data' do
      let(:malicious_data) do
        {
          id: telegram_user_id,
          first_name: "'; DROP TABLE users;--",
          last_name: 'Test',
          username: 'testuser',
          photo_url: 'https://example.com/photo.jpg'
        }
      end

      before do
        OmniAuth.config.mock_auth[:telegram] = OmniAuth::AuthHash.new(
          provider: 'telegram',
          uid: telegram_user_id.to_s,
          info: generate_valid_telegram_auth(malicious_data)
        )
      end

      it 'safely handles malicious input' do
        expect {
          get '/users/auth/telegram/callback'
        }.not_to raise_error

        # Проверяем, что таблица users всё ещё существует
        expect(User.count).to be >= 0
      end

      it 'escapes SQL injection attempt' do
        get '/users/auth/telegram/callback'

        user = User.find_by(telegram_id: telegram_user_id.to_s)
        expect(user.first_name).to eq("'; DROP TABLE users;--")
      end
    end

    context 'with XSS attempt in user data' do
      let(:xss_data) do
        {
          id: telegram_user_id,
          first_name: '<script>alert("XSS")</script>',
          last_name: 'Test',
          username: 'testuser',
          photo_url: 'https://example.com/photo.jpg'
        }
      end

      before do
        OmniAuth.config.mock_auth[:telegram] = OmniAuth::AuthHash.new(
          provider: 'telegram',
          uid: telegram_user_id.to_s,
          info: generate_valid_telegram_auth(xss_data)
        )
      end

      it 'stores XSS attempt as plain text' do
        get '/users/auth/telegram/callback'

        user = User.find_by(telegram_id: telegram_user_id.to_s)
        expect(user.first_name).to eq('<script>alert("XSS")</script>')
      end
    end
  end
end
