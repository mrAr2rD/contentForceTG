# frozen_string_literal: true

module Admin
  class AiSettingsController < Admin::ApplicationController
    def edit
      @ai_config = AiConfiguration.current
    end

    def update
      @ai_config = AiConfiguration.current
      params_to_update = ai_config_params

      # Don't update API key if field was left empty (preserves existing key)
      # Only update if user actually entered a value
      api_key = params_to_update[:openrouter_api_key]
      if api_key.nil? || api_key.strip == ''
        params_to_update.delete(:openrouter_api_key)
      end

      if @ai_config.update(params_to_update)
        redirect_to edit_admin_ai_settings_path, notice: 'Настройки AI успешно обновлены!'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def ai_config_params
      params.require(:ai_configuration).permit(
        :openrouter_api_key,
        :default_model,
        :temperature,
        :max_tokens,
        :custom_system_prompt
      )
    end
  end
end
