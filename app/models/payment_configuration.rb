# frozen_string_literal: true

class PaymentConfiguration < ApplicationRecord
  # Примечание: шифрование отключено пока не настроен RAILS_MASTER_KEY в production
  # encrypts :password_1
  # encrypts :password_2

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

    # Генерация подписи: MD5(MerchantLogin:OutSum:InvId:Password#1)
    signature_string = "#{merchant_login}:#{amount}:#{inv_id}:#{password_1}"
    signature = Digest::MD5.hexdigest(signature_string)

    params = {
      MerchantLogin: merchant_login,
      OutSum: amount,
      InvId: inv_id,
      Description: description,
      SignatureValue: signature,
      IsTest: test_mode? ? 1 : 0
    }

    "#{payment_base_url}?#{params.to_query}"
  end

  # Проверка подписи от Robokassa (для webhook)
  def valid_result_signature?(out_sum, inv_id, signature_value)
    return false unless configured?

    expected = Digest::MD5.hexdigest("#{out_sum}:#{inv_id}:#{password_2}").upcase
    signature_value&.upcase == expected
  end
end
