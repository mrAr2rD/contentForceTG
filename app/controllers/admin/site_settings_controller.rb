# frozen_string_literal: true

module Admin
  class SiteSettingsController < Admin::ApplicationController
    def edit
      @site_config = SiteConfiguration.current
    end

    def update
      @site_config = SiteConfiguration.current

      if @site_config.update(site_config_params)
        redirect_to edit_admin_site_settings_path, notice: "Настройки сайта успешно обновлены!"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def site_config_params
      params.require(:site_configuration).permit(:channel_sites_enabled)
    end
  end
end
