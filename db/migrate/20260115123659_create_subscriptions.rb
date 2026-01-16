class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :plan, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.boolean :cancel_at_period_end, default: false
      t.datetime :canceled_at
      t.datetime :trial_ends_at
      t.jsonb :usage, default: {}
      t.jsonb :limits, default: {}

      t.timestamps
    end

    add_index :subscriptions, :user_id, unique: true unless index_exists?(:subscriptions, :user_id)
    add_index :subscriptions, :status unless index_exists?(:subscriptions, :status)
    add_index :subscriptions, :plan unless index_exists?(:subscriptions, :plan)
  end
end
