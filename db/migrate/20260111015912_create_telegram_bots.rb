class CreateTelegramBots < ActiveRecord::Migration[8.1]
  def change
    create_table :telegram_bots, id: :uuid do |t|
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.string :bot_token  # Will be encrypted in model
      t.string :bot_username
      t.string :channel_id
      t.string :channel_name
      t.boolean :verified, default: false, null: false
      t.datetime :verified_at
      t.jsonb :permissions, default: {}
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :telegram_bots, :bot_username, unique: true
    add_index :telegram_bots, :channel_id
    add_index :telegram_bots, :verified
  end
end
