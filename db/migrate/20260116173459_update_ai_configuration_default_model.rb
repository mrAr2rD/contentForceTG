class UpdateAiConfigurationDefaultModel < ActiveRecord::Migration[8.1]
  def up
    # Обновляем существующую конфигурацию на новую модель по умолчанию
    AiConfiguration.find_each do |config|
      # Обновляем только если используется старая модель по умолчанию
      if config.default_model == 'claude-3-sonnet'
        config.update_column(:default_model, 'deepseek/deepseek-chat')
      end
    end
  end

  def down
    # Откатываем на старую модель по умолчанию
    AiConfiguration.find_each do |config|
      if config.default_model == 'deepseek/deepseek-chat'
        config.update_column(:default_model, 'claude-3-sonnet')
      end
    end
  end
end
