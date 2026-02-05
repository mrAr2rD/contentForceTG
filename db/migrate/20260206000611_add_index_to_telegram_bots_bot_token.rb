# frozen_string_literal: true

class AddIndexToTelegramBotsBotToken < ActiveRecord::Migration[8.1]
  def change
    # Index for fast webhook lookup by bot_token
    # Note: bot_token is encrypted, so this indexes the ciphertext
    add_index :telegram_bots, :bot_token, unique: true, if_not_exists: true
  end
end
