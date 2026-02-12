# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Telegram
  class WebhookService
    def initialize(telegram_bot)
      @bot = telegram_bot
    end

    def setup!
      webhook_url = "#{ENV.fetch('TELEGRAM_WEBHOOK_URL', 'http://localhost:3000')}/webhooks/telegram/#{@bot.bot_token}"

      # Генерируем секрет для аутентификации webhook
      secret_token = SecureRandom.hex(32)

      params = {
        url: webhook_url,
        secret_token: secret_token,
        allowed_updates: [
          'message',
          'channel_post',
          'edited_channel_post',
          'callback_query',
          'my_chat_member',
          'message_reaction',
          'message_reaction_count'
        ]
      }

      result = make_request('setWebhook', params)

      unless result['ok']
        raise "Failed to set webhook: #{result['description']}"
      end

      # Сохраняем секрет в базе данных
      @bot.update!(
        webhook_secret: secret_token,
        last_sync_at: Time.current
      )

      Rails.logger.info("Webhook configured for bot #{@bot.id} at #{webhook_url}")
      result
    end

    def delete!
      result = make_request('deleteWebhook')

      unless result['ok']
        raise "Failed to delete webhook: #{result['description']}"
      end

      result
    end

    def info
      make_request('getWebhookInfo')
    end

    private

    def make_request(method, params = {})
      uri = URI("https://api.telegram.org/bot#{@bot.bot_token}/#{method}")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = params.to_json unless params.empty?
      
      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError => e
      { 'ok' => false, 'description' => e.message }
    end
  end
end
