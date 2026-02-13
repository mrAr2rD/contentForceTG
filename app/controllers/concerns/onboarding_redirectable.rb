# frozen_string_literal: true

# Concern для автоматического редиректа на онбординг
# Подключается в ApplicationController
module OnboardingRedirectable
  extend ActiveSupport::Concern

  included do
    before_action :redirect_to_onboarding_if_needed
  end

  private

  def redirect_to_onboarding_if_needed
    return unless user_signed_in?
    return if skip_onboarding_redirect?
    return unless current_user.onboarding_required?

    redirect_to onboarding_path
  end

  # Пропускаем редирект для определённых контроллеров и действий
  def skip_onboarding_redirect?
    # Пропускаем для страницы онбординга
    return true if controller_name == "onboarding"

    # Пропускаем для Devise контроллеров (вход, выход, регистрация)
    return true if devise_controller?

    # Пропускаем для webhooks и API
    return true if controller_name.start_with?("webhooks", "api")

    # Пропускаем для админки
    return true if controller_path.start_with?("admin")

    # Пропускаем для статических страниц
    return true if controller_name == "pages"

    # Пропускаем для health check
    return true if controller_name == "health"

    false
  end
end
