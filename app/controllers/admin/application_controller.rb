# frozen_string_literal: true

module Admin
  class ApplicationController < ActionController::Base
    include Pundit::Authorization

    before_action :authenticate_user!
    before_action :ensure_admin!

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    layout "admin"

    private

    def ensure_admin!
      unless current_user&.admin?
        Rails.logger.warn("Unauthorized admin access attempt by user #{current_user&.id} from IP #{request.remote_ip}")
        redirect_to root_path, alert: "Доступ запрещен. Требуются права администратора."
      end
    end

    def user_not_authorized
      Rails.logger.warn("Pundit authorization failed for user #{current_user&.id} on #{controller_name}##{action_name}")
      redirect_to(request.referer || admin_root_path, alert: "У вас нет прав для выполнения этого действия.")
    end
  end
end
