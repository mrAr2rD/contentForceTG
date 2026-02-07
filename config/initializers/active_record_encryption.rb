# frozen_string_literal: true

# Active Record Encryption configuration
# Rails 8 uses built-in encryption for sensitive data

Rails.application.configure do
  # Support deterministic encryption (for uniqueness constraints)
  config.active_record.encryption.support_unencrypted_data = true

  # Allow reading old unencrypted values during migration
  config.active_record.encryption.extend_queries = true

  # Настройка ключей шифрования через ENV переменные
  # Для production обязательно установить:
  # - AR_ENCRYPTION_PRIMARY_KEY
  # - AR_ENCRYPTION_DETERMINISTIC_KEY
  # - AR_ENCRYPTION_KEY_DERIVATION_SALT
  #
  # Сгенерировать можно командой: bin/rails db:encryption:init

  if ENV["AR_ENCRYPTION_PRIMARY_KEY"].present?
    config.active_record.encryption.primary_key = ENV["AR_ENCRYPTION_PRIMARY_KEY"]
    config.active_record.encryption.deterministic_key = ENV["AR_ENCRYPTION_DETERMINISTIC_KEY"]
    config.active_record.encryption.key_derivation_salt = ENV["AR_ENCRYPTION_KEY_DERIVATION_SALT"]
  elsif Rails.env.development? || Rails.env.test?
    # Fallback для development/test - фиксированные ключи
    config.active_record.encryption.primary_key = "dev_primary_key_32_bytes_long!!"
    config.active_record.encryption.deterministic_key = "dev_deterministic_key_32_bytes!"
    config.active_record.encryption.key_derivation_salt = "dev_salt_for_key_derivation_32b"
  end
end
