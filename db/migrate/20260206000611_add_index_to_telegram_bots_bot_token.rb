# frozen_string_literal: true

class AddIndexToTelegramBotsBotToken < ActiveRecord::Migration[8.1]
  def change
    # Index for fast webhook lookup by bot_token
    # Note: NOT unique because same bot can publish to multiple channels
    add_index :telegram_bots, :bot_token, if_not_exists: true
  end
end
