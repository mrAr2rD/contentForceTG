# frozen_string_literal: true

# Active Record Encryption configuration
# Rails 8 uses built-in encryption for sensitive data

Rails.application.configure do
  # Active Record Encryption is enabled by default in Rails 8
  # Keys are derived from the master key (config/master.key)

  # Support deterministic encryption (for uniqueness constraints)
  config.active_record.encryption.support_unencrypted_data = true

  # Allow reading old unencrypted values during migration
  config.active_record.encryption.extend_queries = true
end
