class RemoveUniqueIndexFromTelegramBotsUsername < ActiveRecord::Migration[8.1]
  def change
    # Убираем unique constraint на bot_username
    # Теперь несколько пользователей могут использовать одного бота
    # и один бот может публиковать в несколько каналов
    remove_index :telegram_bots, :bot_username, if_exists: true
  end
end
