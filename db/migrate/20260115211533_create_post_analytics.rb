class CreatePostAnalytics < ActiveRecord::Migration[8.1]
  def change
    create_table :post_analytics, id: :uuid do |t|
      t.references :post, null: false, foreign_key: true, type: :uuid
      t.string :telegram_message_id
      t.integer :views, default: 0
      t.integer :forwards, default: 0
      t.jsonb :reactions, default: {}
      t.jsonb :button_clicks, default: {}
      t.datetime :measured_at, null: false

      t.timestamps
    end

    add_index :post_analytics, :telegram_message_id
    add_index :post_analytics, :measured_at
    add_index :post_analytics, [:post_id, :measured_at]
  end
end
