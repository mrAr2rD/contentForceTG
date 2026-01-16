class FixAiConfigurationEncryption < ActiveRecord::Migration[8.1]
  def change
    # Remove old string column
    remove_column :ai_configurations, :openrouter_api_key, :string if column_exists?(:ai_configurations, :openrouter_api_key)

    # Add text column for encrypted data (Rails encrypts stores encrypted value as text)
    add_column :ai_configurations, :openrouter_api_key, :text
  end
end
