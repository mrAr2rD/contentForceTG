# frozen_string_literal: true

module Admin
  class PaymentSettingsController < Admin::ApplicationController
    def edit
      @config = PaymentConfiguration.current
    end

    def update
      @config = PaymentConfiguration.current

      if @config.update(payment_config_params)
        redirect_to edit_admin_payment_settings_path, notice: 'Настройки платежей сохранены'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def payment_config_params
      params.require(:payment_configuration).permit(
        :merchant_login,
        :password_1,
        :password_2,
        :test_mode,
        :enabled
      )
    end
  end
end
