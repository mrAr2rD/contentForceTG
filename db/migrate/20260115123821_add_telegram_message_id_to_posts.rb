class AddTelegramMessageIdToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :telegram_message_id, :bigint
    add_index :posts, :telegram_message_id
  end
end
