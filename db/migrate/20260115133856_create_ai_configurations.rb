class CreateAiConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_configurations, id: :uuid do |t|
      t.string :default_model, default: 'claude-3-sonnet', null: false
      t.jsonb :fallback_models, default: ['gpt-3.5-turbo']
      t.decimal :temperature, precision: 3, scale: 2, default: 0.7
      t.integer :max_tokens, default: 2000
      t.text :custom_system_prompt
      t.jsonb :enabled_features, default: {}

      t.timestamps
    end

    add_index :ai_configurations, :default_model
  end
end
