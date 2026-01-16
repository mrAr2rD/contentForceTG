class CreateAiUsageLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_usage_logs, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :project, null: true, foreign_key: true, type: :uuid
      t.string :model_used, null: false
      t.integer :tokens_used, default: 0, null: false
      t.decimal :cost, precision: 10, scale: 6, default: 0, null: false
      t.integer :purpose, default: 0, null: false

      t.timestamps
    end

    add_index :ai_usage_logs, :model_used
    add_index :ai_usage_logs, :purpose
    add_index :ai_usage_logs, :created_at
    add_index :ai_usage_logs, [:user_id, :created_at]
  end
end
