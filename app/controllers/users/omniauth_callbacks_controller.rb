# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token, only: [ :telegram ]

    def telegram
      auth_info = request.env["omniauth.auth"]["info"]

      begin
        @user = User.from_telegram_auth(auth_info)

        if @user.persisted?
          sign_in_and_redirect @user, event: :authentication
          set_flash_message(:notice, :success, kind: "Telegram") if is_navigational_format?
        else
          session["devise.telegram_data"] = request.env["omniauth.auth"].except("extra")
          redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
        end
      rescue SecurityError => e
        Rails.logger.error("Telegram OAuth security error: #{e.message}. IP: #{request.remote_ip}")
        redirect_to root_path, alert: "Ошибка проверки подлинности Telegram. Попробуйте снова."
      end
    end

    def failure
      redirect_to root_path, alert: "Ошибка аутентификации через Telegram"
    end
  end
end
