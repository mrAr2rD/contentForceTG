# frozen_string_literal: true

# Миграция для хранения AI моделей с реальными ценами
# Заменяет AVAILABLE_MODELS из ai_configuration.rb
class CreateAiModels < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_models, id: :uuid do |t|
      t.string :model_id, null: false          # anthropic/claude-3.5-sonnet
      t.string :name, null: false              # Отображаемое название
      t.string :provider                       # Anthropic, OpenAI, Google, Meta, DeepSeek
      t.string :tier, default: 'free'          # free, starter, pro, business
      t.decimal :input_cost_per_1k, precision: 10, scale: 6, default: 0  # $/1K input tokens
      t.decimal :output_cost_per_1k, precision: 10, scale: 6, default: 0 # $/1K output tokens
      t.integer :max_tokens, default: 4096     # Максимум токенов
      t.boolean :active, default: true         # Доступна ли модель

      t.timestamps
    end

    add_index :ai_models, :model_id, unique: true
    add_index :ai_models, :tier
    add_index :ai_models, :active
    add_index :ai_models, :provider
  end
end
