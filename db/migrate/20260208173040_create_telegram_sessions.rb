class CreateTelegramSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :telegram_sessions, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true

      t.string :phone_number
      t.text :session_string, null: false    # Encrypted
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :telegram_sessions, [:user_id, :active]
  end
end
