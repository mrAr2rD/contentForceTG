class AddApiKeyToAiConfiguration < ActiveRecord::Migration[8.1]
  def change
    add_column :ai_configurations, :openrouter_api_key, :string
  end
end
