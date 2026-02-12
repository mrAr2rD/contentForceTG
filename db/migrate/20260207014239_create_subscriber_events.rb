# frozen_string_literal: true

# События подписчиков канала: подписки, отписки, баны
class CreateSubscriberEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriber_events, id: :uuid do |t|
      t.references :telegram_bot, foreign_key: true, type: :uuid, null: false
      t.references :invite_link, foreign_key: true, type: :uuid, null: true # Опционально
      t.bigint :telegram_user_id                 # ID пользователя в Telegram
      t.string :username                         # Username если есть
      t.string :first_name                       # Имя пользователя
      t.string :event_type, null: false          # joined, left, kicked, banned
      t.jsonb :user_data, default: {}            # Дополнительные данные о пользователе
      t.datetime :event_at, null: false          # Когда произошло событие

      t.timestamps
    end

    add_index :subscriber_events, [ :telegram_bot_id, :event_at ]
    add_index :subscriber_events, :event_type
    add_index :subscriber_events, :telegram_user_id
    add_index :subscriber_events, [ :telegram_bot_id, :event_type ]
  end
end
