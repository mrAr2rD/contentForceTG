# frozen_string_literal: true

# Пригласительные ссылки для Telegram каналов с отслеживанием статистики
class CreateInviteLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :invite_links, id: :uuid do |t|
      t.references :telegram_bot, foreign_key: true, type: :uuid, null: false
      t.string :invite_link, null: false         # t.me/+XXX
      t.string :name                             # Название ссылки (для аналитики)
      t.string :source                           # Источник трафика: vk, instagram, etc.
      t.integer :join_count, default: 0          # Количество присоединившихся
      t.integer :member_limit                    # Лимит участников (null = без лимита)
      t.datetime :expire_date                    # Дата истечения
      t.boolean :creates_join_request, default: false # Требует одобрения
      t.boolean :revoked, default: false         # Отозвана ли ссылка

      t.timestamps
    end

    add_index :invite_links, :invite_link, unique: true
    add_index :invite_links, :source
    add_index :invite_links, :revoked
  end
end
