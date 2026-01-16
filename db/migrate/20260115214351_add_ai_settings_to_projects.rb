class AddAiSettingsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :ai_model, :string, default: 'anthropic/claude-3.5-sonnet'
    add_column :projects, :ai_temperature, :decimal, precision: 3, scale: 2, default: 0.7
    add_column :projects, :system_prompt, :text
    add_column :projects, :writing_style, :string, default: 'professional'
  end
end
