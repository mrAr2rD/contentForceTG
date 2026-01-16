# frozen_string_literal: true

module Webhooks
  class TelegramController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!, raise: false

    def receive
      bot_token = params[:bot_token]
      telegram_bot = TelegramBot.find_by(bot_token: bot_token)

      unless telegram_bot
        render json: { error: 'Bot not found' }, status: :not_found
        return
      end

      # Обрабатываем webhook данные
      update = params.permit!.to_h.except(:controller, :action, :bot_token)
      
      # Логируем для отладки
      Rails.logger.info("Telegram webhook received for bot #{telegram_bot.id}: #{update}")

      # TODO: Обработка различных типов обновлений
      # - message
      # - callback_query
      # - channel_post
      # - my_chat_member (для отслеживания добавления/удаления из каналов)

      head :ok
    rescue StandardError => e
      Rails.logger.error("Telegram webhook error: #{e.message}")
      head :ok # Всегда возвращаем 200, чтобы Telegram не повторял
    end
  end
end
