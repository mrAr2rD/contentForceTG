# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentConfiguration, type: :model do
  let(:config) do
    described_class.create!(
      merchant_login: 'test_merchant',
      password_1: 'test_password_1',
      password_2: 'test_password_2',
      test_mode: true,
      enabled: true
    )
  end

  describe '.current' do
    it 'returns singleton instance' do
      config1 = described_class.current
      config2 = described_class.current

      expect(config1).to eq(config2)
      expect(described_class.count).to eq(1)
    end

    it 'creates default disabled configuration' do
      config = described_class.current

      expect(config.enabled?).to be false
      expect(config.test_mode?).to be true
    end
  end

  describe '#configured?' do
    it 'returns true when fully configured' do
      expect(config.configured?).to be true
    end

    it 'returns false when disabled' do
      config.update!(enabled: false)
      expect(config.configured?).to be false
    end

    it 'returns false when merchant_login is missing' do
      config.update!(merchant_login: '')
      expect(config.configured?).to be false
    end

    it 'returns false when password_1 is missing' do
      config.update!(password_1: '')
      expect(config.configured?).to be false
    end

    it 'returns false when password_2 is missing' do
      config.update!(password_2: '')
      expect(config.configured?).to be false
    end
  end

  describe '#hash_algorithm' do
    it 'returns sha256' do
      expect(config.hash_algorithm).to eq('sha256')
    end
  end

  describe '#generate_payment_url' do
    let(:user) { create(:user) }
    let(:subscription) { create(:subscription, user: user) }
    let(:payment) do
      create(:payment,
             user: user,
             subscription: subscription,
             amount: 1490.0,
             invoice_number: 'INV-12345',
             metadata: { 'plan' => 'pro' })
    end

    context 'when configured' do
      it 'generates payment URL with correct signature' do
        url = config.generate_payment_url(payment)

        expect(url).to include('https://auth.robokassa.ru/Merchant/Index.aspx')
        expect(url).to include('MerchantLogin=test_merchant')
        expect(url).to include('OutSum=1490.0')
        expect(url).to include('InvId=INV-12345')
        expect(url).to include('Description=')
        expect(url).to include('SignatureValue=')
        expect(url).to include('SignatureType=sha256')
        expect(url).to include('IsTest=1')
      end

      it 'generates SHA-256 signature' do
        url = config.generate_payment_url(payment)

        # Извлекаем подпись из URL
        signature = URI.decode_www_form(URI.parse(url).query).to_h['SignatureValue']

        # Вычисляем ожидаемую подпись
        signature_string = "test_merchant:1490.0:INV-12345:test_password_1"
        expected_signature = Digest::SHA256.hexdigest(signature_string)

        expect(signature).to eq(expected_signature)
      end

      it 'includes SignatureType parameter' do
        url = config.generate_payment_url(payment)

        params = URI.decode_www_form(URI.parse(url).query).to_h
        expect(params['SignatureType']).to eq('sha256')
      end

      it 'uses test mode when enabled' do
        url = config.generate_payment_url(payment)

        expect(url).to include('IsTest=1')
      end

      it 'uses production mode when disabled' do
        config.update!(test_mode: false)
        url = config.generate_payment_url(payment)

        expect(url).to include('IsTest=0')
      end
    end

    context 'when not configured' do
      before do
        config.update!(enabled: false)
      end

      it 'returns nil' do
        expect(config.generate_payment_url(payment)).to be_nil
      end
    end
  end

  describe '#valid_result_signature?' do
    let(:out_sum) { '1490.0' }
    let(:inv_id) { 'INV-12345' }

    context 'with valid SHA-256 signature' do
      let(:signature_string) { "#{out_sum}:#{inv_id}:#{config.password_2}" }
      let(:valid_signature) { Digest::SHA256.hexdigest(signature_string).upcase }

      it 'returns true' do
        expect(config.valid_result_signature?(out_sum, inv_id, valid_signature)).to be true
      end

      it 'is case insensitive' do
        lowercase_signature = Digest::SHA256.hexdigest(signature_string).downcase

        expect(config.valid_result_signature?(out_sum, inv_id, lowercase_signature)).to be true
      end

      it 'uses secure_compare to prevent timing attacks' do
        expect(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_call_original

        config.valid_result_signature?(out_sum, inv_id, valid_signature)
      end
    end

    context 'with invalid signature' do
      it 'returns false' do
        invalid_signature = Digest::SHA256.hexdigest('wrong:data:here').upcase

        expect(config.valid_result_signature?(out_sum, inv_id, invalid_signature)).to be false
      end

      it 'returns false for MD5 signature (old algorithm)' do
        # Пытаемся использовать старую MD5 подпись
        md5_signature = Digest::MD5.hexdigest("#{out_sum}:#{inv_id}:#{config.password_2}").upcase

        expect(config.valid_result_signature?(out_sum, inv_id, md5_signature)).to be false
      end

      it 'returns false for nil signature' do
        expect(config.valid_result_signature?(out_sum, inv_id, nil)).to be false
      end

      it 'returns false for empty signature' do
        expect(config.valid_result_signature?(out_sum, inv_id, '')).to be false
      end
    end

    context 'when not configured' do
      before do
        config.update!(enabled: false)
      end

      it 'returns false' do
        valid_signature = Digest::SHA256.hexdigest("#{out_sum}:#{inv_id}:test_password_2").upcase

        expect(config.valid_result_signature?(out_sum, inv_id, valid_signature)).to be false
      end
    end
  end

  describe 'encryption' do
    context 'when encryption is configured' do
      before do
        # Пропускаем если encryption keys не настроены
        skip 'Encryption keys not configured' unless ENV['AR_ENCRYPTION_PRIMARY_KEY'].present?
      end

      it 'encrypts password_1' do
        config = described_class.create!(
          merchant_login: 'test',
          password_1: 'secret_password_1',
          password_2: 'secret_password_2',
          enabled: true
        )

        # В базе данных пароль должен быть зашифрован (не plain text)
        raw_value = ActiveRecord::Base.connection.select_value(
          "SELECT password_1 FROM payment_configurations WHERE id = '#{config.id}'"
        )

        expect(raw_value).not_to eq('secret_password_1')
      end

      it 'encrypts password_2' do
        config = described_class.create!(
          merchant_login: 'test',
          password_1: 'secret_password_1',
          password_2: 'secret_password_2',
          enabled: true
        )

        raw_value = ActiveRecord::Base.connection.select_value(
          "SELECT password_2 FROM payment_configurations WHERE id = '#{config.id}'"
        )

        expect(raw_value).not_to eq('secret_password_2')
      end

      it 'decrypts passwords when reading' do
        config = described_class.create!(
          merchant_login: 'test',
          password_1: 'secret_password_1',
          password_2: 'secret_password_2',
          enabled: true
        )

        config.reload
        expect(config.password_1).to eq('secret_password_1')
        expect(config.password_2).to eq('secret_password_2')
      end
    end
  end

  describe 'Security edge cases' do
    let(:out_sum) { '1000.0' }
    let(:inv_id) { 'INV-123' }

    it 'handles SQL injection attempts in parameters' do
      malicious_sum = "1000.0'; DROP TABLE payments;--"
      signature = Digest::SHA256.hexdigest("#{malicious_sum}:#{inv_id}:#{config.password_2}")

      expect {
        config.valid_result_signature?(malicious_sum, inv_id, signature)
      }.not_to raise_error

      # Проверяем, что таблица payments всё ещё существует
      expect(Payment.count).to be >= 0
    end

    it 'handles extremely large amounts' do
      large_sum = '9' * 1000
      signature = Digest::SHA256.hexdigest("#{large_sum}:#{inv_id}:#{config.password_2}")

      expect {
        config.valid_result_signature?(large_sum, inv_id, signature)
      }.not_to raise_error
    end

    it 'handles special characters in invoice_number' do
      special_inv = 'INV-!@#$%^&*()'
      signature = Digest::SHA256.hexdigest("#{out_sum}:#{special_inv}:#{config.password_2}")

      result = config.valid_result_signature?(out_sum, special_inv, signature)
      expect(result).to be true
    end

    it 'handles unicode characters' do
      unicode_sum = '1000.0🔒'
      signature = Digest::SHA256.hexdigest("#{unicode_sum}:#{inv_id}:#{config.password_2}")

      expect {
        config.valid_result_signature?(unicode_sum, inv_id, signature)
      }.not_to raise_error
    end
  end
end
