class CreateChannelSubscriberMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :channel_subscriber_metrics, id: :uuid do |t|
      t.references :telegram_bot, null: false, foreign_key: true, type: :uuid
      t.integer :subscriber_count, default: 0
      t.integer :subscriber_growth, default: 0
      t.decimal :churn_rate, precision: 5, scale: 2, default: 0.0
      t.datetime :measured_at, null: false

      t.timestamps
    end

    add_index :channel_subscriber_metrics, :measured_at
    add_index :channel_subscriber_metrics, [:telegram_bot_id, :measured_at]
  end
end
