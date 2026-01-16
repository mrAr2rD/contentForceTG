# frozen_string_literal: true

module Admin
  class ApplicationController < ActionController::Base
    before_action :authenticate_user!
    before_action :ensure_admin!

    layout 'admin'

    private

    def ensure_admin!
      unless current_user&.admin?
        redirect_to root_path, alert: "Доступ запрещен. Требуются права администратора."
      end
    end
  end
end
