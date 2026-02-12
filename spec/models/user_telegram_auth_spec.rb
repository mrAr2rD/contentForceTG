# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, 'Telegram OAuth Authentication', type: :model do
  let(:bot_token) { ENV.fetch('TELEGRAM_BOT_TOKEN', 'test_bot_token') }
  let(:telegram_user_id) { 123456789 }
  let(:auth_date) { Time.current.to_i }
  let(:base_auth_data) do
    {
      'id' => telegram_user_id.to_s,
      'first_name' => 'John',
      'last_name' => 'Doe',
      'username' => 'johndoe',
      'photo_url' => 'https://example.com/photo.jpg',
      'auth_date' => auth_date.to_s
    }
  end

  before do
    ENV['TELEGRAM_BOT_TOKEN'] = bot_token
  end

  describe '.verify_telegram_auth_data' do
    context 'with valid signature' do
      let(:auth_data) do
        data = base_auth_data.dup
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

      it 'returns true' do
        expect(User.verify_telegram_auth_data(auth_data)).to be true
      end

      it 'uses secure_compare for hash comparison' do
        expect(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_call_original

        User.verify_telegram_auth_data(auth_data)
      end
    end

    context 'with invalid signature' do
      let(:auth_data) do
        data = base_auth_data.dup
        data['hash'] = 'invalid_hash_value'
        data
      end

      it 'returns false' do
        expect(User.verify_telegram_auth_data(auth_data)).to be false
      end

      it 'does not raise an error' do
        expect {
          User.verify_telegram_auth_data(auth_data)
        }.not_to raise_error
      end
    end

    context 'without hash parameter' do
      let(:auth_data) { base_auth_data.dup }

      it 'returns false' do
        expect(User.verify_telegram_auth_data(auth_data)).to be false
      end
    end

    context 'with empty hash' do
      let(:auth_data) do
        data = base_auth_data.dup
        data['hash'] = ''
        data
      end

      it 'returns false' do
        expect(User.verify_telegram_auth_data(auth_data)).to be false
      end
    end

    context 'with expired auth_date' do
      let(:auth_data) do
        data = base_auth_data.dup
        data['auth_date'] = 25.hours.ago.to_i.to_s # Старше 24 часов

        # Генерируем правильную подпись для этих данных
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

      it 'returns false' do
        expect(User.verify_telegram_auth_data(auth_data)).to be false
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn).with(/Auth data too old/)

        User.verify_telegram_auth_data(auth_data)
      end
    end

    context 'with tampered data' do
      let(:auth_data) do
        data = base_auth_data.dup

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

        # Теперь изменяем данные после генерации подписи
        data['id'] = '999999999'

        data
      end

      it 'returns false' do
        expect(User.verify_telegram_auth_data(auth_data)).to be false
      end
    end

    context 'with special characters in data' do
      let(:auth_data) do
        data = base_auth_data.merge(
          'first_name' => "O'Reilly",
          'last_name' => 'Test & Demo',
          'username' => 'user_name'
        )

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

      it 'correctly validates data with special characters' do
        expect(User.verify_telegram_auth_data(auth_data)).to be true
      end
    end

    context 'with unicode characters' do
      let(:auth_data) do
        data = base_auth_data.merge(
          'first_name' => 'Иван',
          'last_name' => 'Петров'
        )

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

      it 'correctly validates unicode data' do
        expect(User.verify_telegram_auth_data(auth_data)).to be true
      end
    end
  end

  describe '.from_telegram_auth' do
    context 'with valid auth data' do
      let(:valid_auth_data) do
        data = base_auth_data.dup

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

      it 'creates a new user' do
        expect {
          User.from_telegram_auth(valid_auth_data)
        }.to change(User, :count).by(1)
      end

      it 'sets user attributes from auth data' do
        user = User.from_telegram_auth(valid_auth_data)

        expect(user.telegram_id).to eq(telegram_user_id.to_s)
        expect(user.first_name).to eq('John')
        expect(user.last_name).to eq('Doe')
        expect(user.telegram_username).to eq('johndoe')
        expect(user.avatar_url).to eq('https://example.com/photo.jpg')
      end

      it 'generates email for user without email' do
        user = User.from_telegram_auth(valid_auth_data)

        expect(user.email).to eq("telegram_#{telegram_user_id}@contentforce.local")
      end

      it 'updates existing user' do
        existing_user = create(:user, telegram_id: telegram_user_id.to_s)

        expect {
          User.from_telegram_auth(valid_auth_data)
        }.not_to change(User, :count)

        existing_user.reload
        expect(existing_user.first_name).to eq('John')
      end
    end

    context 'with invalid auth data' do
      let(:invalid_auth_data) do
        data = base_auth_data.dup
        data['hash'] = 'invalid_hash'
        data
      end

      it 'raises SecurityError' do
        expect {
          User.from_telegram_auth(invalid_auth_data)
        }.to raise_error(SecurityError, /Invalid Telegram authentication data/)
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Invalid signature/)

        begin
          User.from_telegram_auth(invalid_auth_data)
        rescue SecurityError
          # Expected
        end
      end

      it 'does not create a user' do
        expect {
          begin
            User.from_telegram_auth(invalid_auth_data)
          rescue SecurityError
            # Expected
          end
        }.not_to change(User, :count)
      end
    end

    context 'with missing hash' do
      let(:auth_data_without_hash) { base_auth_data.dup }

      it 'raises SecurityError' do
        expect {
          User.from_telegram_auth(auth_data_without_hash)
        }.to raise_error(SecurityError)
      end
    end
  end

  describe 'Replay attack protection' do
    let(:valid_auth_data) do
      data = base_auth_data.merge('auth_date' => 23.hours.ago.to_i.to_s)

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

    it 'accepts auth data within 24 hours' do
      expect(User.verify_telegram_auth_data(valid_auth_data)).to be true
    end

    it 'rejects auth data older than 24 hours' do
      expired_data = valid_auth_data.dup
      expired_data['auth_date'] = 25.hours.ago.to_i.to_s

      # Пересчитываем подпись
      data_check_arr = expired_data.except('hash').map { |k, v| "#{k}=#{v}" }.sort
      data_check_string = data_check_arr.join("\n")
      secret_key = Digest::SHA256.digest(bot_token)
      hash = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha256'),
        secret_key,
        data_check_string
      )
      expired_data['hash'] = hash

      expect(User.verify_telegram_auth_data(expired_data)).to be false
    end
  end
end
