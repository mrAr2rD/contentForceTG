# frozen_string_literal: true

module Telegram
  # Сервис для получения статистики постов через Pyrogram (MTProto API)
  # Bot API не предоставляет views/reactions, поэтому используем Client API
  class PostStatsService
    PYTHON_SERVICE_URL = ENV.fetch("TELEGRAM_PARSER_URL", "http://localhost:8000")
    REQUEST_TIMEOUT = 30

    def initialize(telegram_bot)
      @telegram_bot = telegram_bot
    end

    # Получить статистику для одного поста
    def fetch_single(post)
      return nil unless post.telegram_message_id.present?

      stats = fetch_stats([ post.telegram_message_id ])
      stats&.first
    end

    # Получить статистику для нескольких постов
    def fetch_batch(posts)
      message_ids = posts.map(&:telegram_message_id).compact
      return [] if message_ids.empty?

      fetch_stats(message_ids)
    end

    # Получить статистику для всех опубликованных постов бота
    def fetch_all_published
      posts = @telegram_bot.posts.published.where.not(telegram_message_id: nil)
      fetch_batch(posts)
    end

    private

    def fetch_stats(message_ids)
      telegram_session = find_telegram_session
      return nil unless telegram_session

      response = request_stats(telegram_session, message_ids)

      if response[:success]
        response[:stats]
      else
        Rails.logger.error("PostStatsService error: #{response[:error]}")
        nil
      end
    rescue StandardError => e
      Rails.logger.error("PostStatsService exception: #{e.message}")
      nil
    end

    def find_telegram_session
      # Ищем активную сессию у владельца проекта
      user = @telegram_bot.project&.user
      return nil unless user

      session = user.telegram_sessions.active.authorized.first
      unless session
        Rails.logger.warn("No active Telegram session for user #{user.id}")
      end
      session
    end

    def request_stats(telegram_session, message_ids)
      uri = URI("#{PYTHON_SERVICE_URL}/message-stats")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = REQUEST_TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = {
        channel_username: channel_username,
        message_ids: message_ids,
        session_string: telegram_session.session_string
      }.to_json

      response = http.request(request)
      body = JSON.parse(response.body, symbolize_names: true)

      if response.code.to_i == 200 && body[:success]
        { success: true, stats: body[:stats] }
      else
        { success: false, error: body[:error] || "Ошибка сервиса" }
      end
    rescue Net::OpenTimeout, Net::ReadTimeout
      { success: false, error: "Сервис статистики недоступен (timeout)" }
    rescue Errno::ECONNREFUSED
      { success: false, error: "Не удалось подключиться к сервису статистики" }
    rescue JSON::ParserError
      { success: false, error: "Некорректный ответ от сервиса" }
    end

    def channel_username
      # channel_id может быть в формате @username или -100123456789
      if @telegram_bot.channel_id.present? && @telegram_bot.channel_id.start_with?("@")
        @telegram_bot.channel_id.delete("@")
      else
        @telegram_bot.channel_name || @telegram_bot.bot_username
      end
    end
  end
end
