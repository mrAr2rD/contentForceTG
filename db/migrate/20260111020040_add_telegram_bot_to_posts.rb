class AddTelegramBotToPosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :telegram_bot, null: false, foreign_key: true, type: :uuid
  end
end
