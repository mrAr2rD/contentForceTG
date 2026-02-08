# frozen_string_literal: true

class TelegramSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_telegram_session, only: [:destroy]

  layout "dashboard"

  def index
    @telegram_sessions = current_user.telegram_sessions.order(created_at: :desc)
  end

  def new
    @telegram_session = current_user.telegram_sessions.build
  end

  def send_code
    phone = params[:phone_number]&.strip

    if phone.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "auth_form",
            partial: "telegram_sessions/phone_form",
            locals: { error: "Введите номер телефона" }
          )
        end
        format.html { redirect_to new_telegram_session_path, alert: "Введите номер телефона" }
      end
      return
    end

    # Вызов Python microservice
    result = Telegram::AuthService.new.send_code(phone)

    if result[:success]
      @telegram_session = current_user.telegram_sessions.create!(
        phone_number: phone,
        phone_code_hash: result[:phone_code_hash],
        auth_status: :pending_code,
        auth_expires_at: 5.minutes.from_now
      )

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "auth_form",
            partial: "telegram_sessions/code_form",
            locals: { telegram_session: @telegram_session }
          )
        end
        format.html { redirect_to new_telegram_session_path }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "auth_form",
            partial: "telegram_sessions/phone_form",
            locals: { error: result[:error] || "Ошибка отправки кода" }
          )
        end
        format.html { redirect_to new_telegram_session_path, alert: result[:error] }
      end
    end
  end

  def verify_code
    @telegram_session = current_user.telegram_sessions.find(params[:id])

    if @telegram_session.auth_expired?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "auth_form",
            partial: "telegram_sessions/phone_form",
            locals: { error: "Код истёк, запросите новый" }
          )
        end
        format.html { redirect_to new_telegram_session_path, alert: "Код истёк" }
      end
      return
    end

    result = Telegram::AuthService.new.verify_code(
      @telegram_session.phone_number,
      @telegram_session.phone_code_hash,
      params[:phone_code]
    )

    if result[:success]
      @telegram_session.complete_authorization!(result[:session_string])

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "auth_form",
            partial: "telegram_sessions/success",
            locals: { telegram_session: @telegram_session }
          )
        end
        format.html { redirect_to telegram_sessions_path, notice: "Telegram авторизован" }
      end
    elsif result[:requires_2fa]
      @telegram_session.require_2fa!

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "auth_form",
            partial: "telegram_sessions/twofa_form",
            locals: { telegram_session: @telegram_session }
          )
        end
        format.html { render :new }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "auth_form",
            partial: "telegram_sessions/code_form",
            locals: { telegram_session: @telegram_session, error: result[:error] || "Неверный код" }
          )
        end
        format.html { redirect_to new_telegram_session_path, alert: result[:error] }
      end
    end
  end

  def verify_2fa
    @telegram_session = current_user.telegram_sessions.find(params[:id])

    result = Telegram::AuthService.new.verify_2fa(
      @telegram_session.phone_number,
      params[:password]
    )

    if result[:success]
      @telegram_session.complete_authorization!(result[:session_string])

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "auth_form",
            partial: "telegram_sessions/success",
            locals: { telegram_session: @telegram_session }
          )
        end
        format.html { redirect_to telegram_sessions_path, notice: "Telegram авторизован" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "auth_form",
            partial: "telegram_sessions/twofa_form",
            locals: { telegram_session: @telegram_session, error: result[:error] || "Неверный пароль" }
          )
        end
        format.html { redirect_to new_telegram_session_path, alert: result[:error] }
      end
    end
  end

  def destroy
    @telegram_session.destroy
    redirect_to telegram_sessions_path, notice: "Сессия удалена"
  end

  private

  def set_telegram_session
    @telegram_session = current_user.telegram_sessions.find(params[:id])
  end
end
