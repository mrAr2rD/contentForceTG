# frozen_string_literal: true

module Admin
  class AiSettingsController < Admin::ApplicationController
    def edit
      @ai_config = AiConfiguration.current
    end

    def update
      @ai_config = AiConfiguration.current
      params_to_update = ai_config_params

      # Handle API key update logic
      # Only update API key if user actually entered a non-blank value
      api_key = params_to_update[:openrouter_api_key]

      # Log for debugging (remove after fixing)
      Rails.logger.info "=== AI Settings Update Debug ==="
      Rails.logger.info "Received API key param: #{api_key.inspect}"
      Rails.logger.info "API key blank?: #{api_key.blank?}"
      Rails.logger.info "Current API key present?: #{@ai_config.openrouter_api_key.present?}"

      if api_key.blank?
        # If blank, don't update the API key field at all (preserve existing)
        params_to_update.delete(:openrouter_api_key)
        Rails.logger.info "Removing API key from params (blank)"
      else
        # User entered a value, so update it
        Rails.logger.info "Keeping API key in params: #{api_key[0..10]}..."
      end

      Rails.logger.info "Params to update: #{params_to_update.except(:openrouter_api_key).inspect}"

      if @ai_config.update(params_to_update)
        Rails.logger.info "Update successful! New API key present?: #{@ai_config.reload.openrouter_api_key.present?}"
        redirect_to edit_admin_ai_settings_path, notice: 'Настройки AI успешно обновлены!'
      else
        Rails.logger.error "Update failed! Errors: #{@ai_config.errors.full_messages}"
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
