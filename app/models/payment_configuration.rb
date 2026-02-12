# frozen_string_literal: true

class PaymentConfiguration < ApplicationRecord
  # Шифрование паролей (требуется настройка encryption keys в ENV)
  encrypts :password_1
  encrypts :password_2

  # Валидации
  validates :merchant_login, presence: true, if: :enabled?

  # Singleton pattern - только одна конфигурация
  def self.current
    first_or_create!(
      merchant_login: '',
      password_1: '',
      password_2: '',
      test_mode: true,
      enabled: false
    )
  end

  # Проверка полной настройки
  def configured?
    enabled? && merchant_login.present? && password_1.present? && password_2.present?
  end

  # Алгоритм хеширования для Robokassa
  def hash_algorithm
    'sha256' # Robokassa поддерживает md5, sha1, sha256, sha512
  end

  # URL для оплаты (тестовый или боевой)
  def payment_base_url
    if test_mode?
      'https://auth.robokassa.ru/Merchant/Index.aspx'
    else
      'https://auth.robokassa.ru/Merchant/Index.aspx'
    end
  end

  # Генерация URL для оплаты
  def generate_payment_url(payment)
    return nil unless configured?

    amount = payment.amount.to_f
    inv_id = payment.invoice_number
    description = "Подписка ContentForce - #{payment.metadata['plan']&.titleize}"

    # Генерация подписи: SHA256(MerchantLogin:OutSum:InvId:Password#1)
    signature_string = "#{merchant_login}:#{amount}:#{inv_id}:#{password_1}"
    signature = Digest::SHA256.hexdigest(signature_string)

    params = {
      MerchantLogin: merchant_login,
      OutSum: amount,
      InvId: inv_id,
      Description: description,
      SignatureValue: signature,
      SignatureType: hash_algorithm,
      IsTest: test_mode? ? 1 : 0
    }

    "#{payment_base_url}?#{params.to_query}"
  end

  # Проверка подписи от Robokassa (для webhook)
  def valid_result_signature?(out_sum, inv_id, signature_value)
    return false unless configured?

    # Генерация ожидаемой подписи: SHA256(OutSum:InvId:Password#2)
    signature_string = "#{out_sum}:#{inv_id}:#{password_2}"
    expected = Digest::SHA256.hexdigest(signature_string)

    # Защита от timing attacks через secure_compare
    ActiveSupport::SecurityUtils.secure_compare(
      signature_value.to_s.upcase,
      expected.upcase
    )
  end
end
