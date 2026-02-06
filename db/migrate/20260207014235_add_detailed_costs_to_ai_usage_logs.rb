# frozen_string_literal: true

# Добавляет детализацию токенов и стоимости в логи использования AI
class AddDetailedCostsToAiUsageLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :ai_usage_logs, :input_tokens, :integer, default: 0
    add_column :ai_usage_logs, :output_tokens, :integer, default: 0
    add_column :ai_usage_logs, :input_cost, :decimal, precision: 10, scale: 6, default: 0
    add_column :ai_usage_logs, :output_cost, :decimal, precision: 10, scale: 6, default: 0
  end
end
