class CreateChannelSites < ActiveRecord::Migration[8.1]
  def change
    create_table :channel_sites, id: :uuid do |t|
      t.references :telegram_bot, type: :uuid, null: false, foreign_key: true
      t.references :project, type: :uuid, null: false, foreign_key: true

      # Домены
      t.string :subdomain                    # mychannel.contentforce.app
      t.string :custom_domain                # blog.example.com
      t.boolean :custom_domain_verified, default: false
      t.string :domain_verification_token

      # Настройки сайта
      t.string :site_title
      t.text :site_description
      t.string :theme, default: 'default'
      t.jsonb :settings, default: {}

      # SEO
      t.string :meta_title
      t.text :meta_description

      # Статус
      t.boolean :enabled, default: false
      t.datetime :last_synced_at
      t.integer :posts_count, default: 0

      t.timestamps
    end

    add_index :channel_sites, :subdomain, unique: true, where: "subdomain IS NOT NULL"
    add_index :channel_sites, :custom_domain, unique: true, where: "custom_domain IS NOT NULL"
    add_index :channel_sites, :enabled
  end
end
