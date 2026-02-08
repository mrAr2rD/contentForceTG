class CreateChannelPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :channel_posts, id: :uuid do |t|
      t.references :channel_site, type: :uuid, null: false, foreign_key: true

      # Telegram данные
      t.bigint :telegram_message_id, null: false
      t.datetime :telegram_date, null: false
      t.text :original_text
      t.jsonb :media, default: []
      t.integer :views_count, default: 0

      # Контент для сайта
      t.string :title
      t.string :slug
      t.text :content
      t.text :excerpt

      # Настройки отображения
      t.integer :visibility, default: 0      # auto, visible, hidden
      t.boolean :featured, default: false

      # Статистика сайта
      t.integer :site_views_count, default: 0

      t.timestamps
    end

    add_index :channel_posts, [:channel_site_id, :telegram_message_id], unique: true, name: 'idx_channel_posts_on_site_and_message'
    add_index :channel_posts, [:channel_site_id, :slug], unique: true, where: "slug IS NOT NULL", name: 'idx_channel_posts_on_site_and_slug'
    add_index :channel_posts, :visibility
    add_index :channel_posts, :featured
    add_index :channel_posts, :telegram_date
  end
end
