class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Pundit authorization
  include Pundit::Authorization

  # Include date helpers
  include ActionView::Helpers::DateHelper

  # Pundit error handling
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Устанавливаем часовой пояс пользователя для корректной работы Time.zone
  around_action :set_time_zone, if: :current_user

  # Redirect to dashboard after sign in
  def after_sign_in_path_for(resource)
    dashboard_path
  end

  private

  def set_time_zone
    Time.use_zone(current_user.time_zone) { yield }
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
