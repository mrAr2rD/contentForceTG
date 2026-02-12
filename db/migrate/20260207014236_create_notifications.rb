# frozen_string_literal: true

# Таблица уведомлений пользователям
class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid, null: false
      t.string :notification_type, null: false   # payment_success, subscription_expiring, etc.
      t.string :channel, null: false             # email, telegram
      t.string :status, default: 'pending'       # pending, sent, failed, read
      t.string :subject                          # Тема для email
      t.text :body                               # Тело сообщения
      t.jsonb :metadata, default: {}             # Дополнительные данные
      t.datetime :sent_at                        # Когда отправлено
      t.datetime :read_at                        # Когда прочитано

      t.timestamps
    end

    add_index :notifications, :notification_type
    add_index :notifications, :channel
    add_index :notifications, :status
    add_index :notifications, [ :user_id, :created_at ]
  end
end
