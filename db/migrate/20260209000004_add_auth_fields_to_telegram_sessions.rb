# frozen_string_literal: true

class AddAuthFieldsToTelegramSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :telegram_sessions, :phone_code_hash, :string
    add_column :telegram_sessions, :auth_status, :integer, default: 0
    add_column :telegram_sessions, :auth_expires_at, :datetime

    # Сделать session_string nullable для процесса авторизации
    change_column_null :telegram_sessions, :session_string, true

    add_index :telegram_sessions, :auth_status
  end
end
