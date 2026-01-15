# frozen_string_literal: true

module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin!

    # Administrate использует request.env['warden'].user, но мы используем Devise
    def current_user
      @current_user ||= warden.authenticate(scope: :user)
    end

    private

    def ensure_admin!
      unless current_user&.admin?
        redirect_to root_path, alert: "Доступ запрещен"
      end
    end
  end
end
