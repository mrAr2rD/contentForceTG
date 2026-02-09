# frozen_string_literal: true

module Telegram
  # Сервис для получения информации о канале через Pyrogram (MTProto API)
  class ChannelInfoService
    PYTHON_SERVICE_URL = ENV.fetch("TELEGRAM_PARSER_URL", "http://localhost:8000")
    REQUEST_TIMEOUT = 30

    def initialize(telegram_bot)
      @telegram_bot = telegram_bot
    end

    # Получить информацию о канале (подписчики, название)
    def fetch
      telegram_session = find_telegram_session
      return nil unless telegram_session

      response = request_channel_info(telegram_session)

      if response[:success]
        response[:channel]
      else
        Rails.logger.error("ChannelInfoService error: #{response[:error]}")
        nil
      end
    rescue StandardError => e
      Rails.logger.error("ChannelInfoService exception: #{e.message}")
      nil
    end

    private

    def find_telegram_session
      user = @telegram_bot.project&.user
      return nil unless user

      session = user.telegram_sessions.active.authorized.first
      unless session
        Rails.logger.warn("No active Telegram session for user #{user.id}")
      end
      session
    end

    def request_channel_info(telegram_session)
      uri = URI("#{PYTHON_SERVICE_URL}/channel-info")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = REQUEST_TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = {
        channel_username: channel_username,
        session_string: telegram_session.session_string
      }.to_json

      response = http.request(request)
      body = JSON.parse(response.body, symbolize_names: true)

      if response.code.to_i == 200 && body[:success]
        { success: true, channel: body[:channel] }
      else
        { success: false, error: body[:error] || "Ошибка сервиса" }
      end
    rescue Net::OpenTimeout, Net::ReadTimeout
      { success: false, error: "Сервис недоступен (timeout)" }
    rescue Errno::ECONNREFUSED
      { success: false, error: "Не удалось подключиться к сервису" }
    rescue JSON::ParserError
      { success: false, error: "Некорректный ответ от сервиса" }
    end

    def channel_username
      if @telegram_bot.channel_id.present? && @telegram_bot.channel_id.start_with?("@")
        @telegram_bot.channel_id.delete("@")
      else
        @telegram_bot.channel_name || @telegram_bot.bot_username
      end
    end
  end
end
