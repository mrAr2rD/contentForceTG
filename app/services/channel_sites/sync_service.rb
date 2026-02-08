# frozen_string_literal: true

module ChannelSites
  class SyncService
    PYTHON_SERVICE_URL = ENV.fetch("TELEGRAM_PARSER_URL", "http://localhost:8000")

    def initialize(channel_site)
      @channel_site = channel_site
    end

    def call
      # Получаем сессию пользователя для Pyrogram
      telegram_session = @channel_site.project.user.telegram_sessions.active.first

      unless telegram_session
        return { success: false, error: "Telegram сессия не найдена. Подключите аккаунт." }
      end

      # Вызываем Python microservice
      response = request_sync(telegram_session)

      if response[:success]
        @channel_site.update(last_synced_at: Time.current)
        { success: true, message: "Синхронизация запущена" }
      else
        { success: false, error: response[:error] }
      end
    rescue StandardError => e
      Rails.logger.error("ChannelSites::SyncService error: #{e.message}")
      { success: false, error: e.message }
    end

    private

    def request_sync(telegram_session)
      uri = URI("#{PYTHON_SERVICE_URL}/sync")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = {
        channel_site_id: @channel_site.id,
        channel_username: channel_username,
        session_string: telegram_session.session_string,
        callback_url: callback_url
      }.to_json

      response = http.request(request)

      if response.code.to_i == 200
        { success: true }
      else
        body = JSON.parse(response.body) rescue {}
        { success: false, error: body["error"] || "Ошибка сервиса парсинга" }
      end
    rescue Net::OpenTimeout, Net::ReadTimeout
      { success: false, error: "Сервис парсинга недоступен" }
    rescue Errno::ECONNREFUSED
      { success: false, error: "Не удалось подключиться к сервису парсинга" }
    end

    def channel_username
      @channel_site.telegram_bot.channel_username ||
        @channel_site.telegram_bot.bot_username
    end

    def callback_url
      Rails.application.routes.url_helpers.webhooks_channel_sync_url(
        host: ENV.fetch("APP_HOST", "localhost:3000"),
        protocol: Rails.env.production? ? "https" : "http"
      )
    end
  end
end
