# frozen_string_literal: true

# Active Record Encryption configuration
# Rails 8 uses built-in encryption for sensitive data

Rails.application.configure do
  # Support deterministic encryption (for uniqueness constraints)
  config.active_record.encryption.support_unencrypted_data = true

  # Allow reading old unencrypted values during migration
  config.active_record.encryption.extend_queries = true

  # Ключи шифрования - берём из ENV или используем fallback
  # ВАЖНО: В production рекомендуется установить собственные ключи через ENV
  primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY", "prod_primary_key_32bytes_long!!")
  deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY", "prod_deterministic_32bytes_key!")
  key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT", "prod_salt_for_derivation_32byte")

  config.active_record.encryption.primary_key = primary_key
  config.active_record.encryption.deterministic_key = deterministic_key
  config.active_record.encryption.key_derivation_salt = key_derivation_salt

  # Логируем предупреждение если используются дефолтные ключи в production
  if Rails.env.production? && !ENV["AR_ENCRYPTION_PRIMARY_KEY"].present?
    Rails.logger.warn "WARNING: Using default encryption keys in production! Set AR_ENCRYPTION_* env vars."
  end
end
