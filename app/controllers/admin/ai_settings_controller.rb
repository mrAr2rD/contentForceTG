# frozen_string_literal: true

module Admin
  class AiSettingsController < Admin::ApplicationController
    def edit
      @ai_config = AiConfiguration.current
    end

    def update
      @ai_config = AiConfiguration.current

      if @ai_config.update(ai_config_params)
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
