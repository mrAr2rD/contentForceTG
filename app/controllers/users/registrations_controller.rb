# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout :resolve_layout

  protected

  # Разрешаем обновление без пароля для Telegram-пользователей или если пароль не меняется
  def update_resource(resource, params)
    if params[:password].blank? && params[:password_confirmation].blank?
      resource.update_without_password(params.except(:current_password))
    else
      super
    end
  end

  def account_update_params
    params.require(:user).permit(:email, :password, :password_confirmation,
                                  :current_password, :time_zone)
  end

  private

  def resolve_layout
    if action_name == "edit" || action_name == "update"
      "dashboard"
    else
      "application"
    end
  end
end
