# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Telegram
  class PublishService
    def initialize(post)
      @post = post
      @bot = post.telegram_bot
    end

    def publish!
      raise 'No Telegram bot configured' unless @bot
      raise 'Bot not verified' unless @bot.verified?
      raise 'No channel configured' unless @bot.channel_id.present?

      result = send_message
      
      if result['ok']
        message_id = result['result']['message_id']
        
        OpenStruct.new(
          success: true,
          message_id: message_id
        )
      else
        error_message = result['description'] || 'Unknown error'
        raise "Failed to publish: #{error_message}"
      end
    end

    private

    def send_message
      params = {
        chat_id: @bot.channel_id,
        text: format_content(@post.content),
        parse_mode: 'HTML'
      }

      # Добавляем кнопку если есть
      if @post.respond_to?(:button_text) && @post.button_text.present?
        params[:reply_markup] = {
          inline_keyboard: [[
            { text: @post.button_text, url: @post.button_url }
          ]]
        }
      end

      make_request('sendMessage', params)
    end

    def format_content(content)
      # Конвертируем Markdown в HTML для Telegram
      content
        .gsub(/\*\*(.+?)\*\*/, '<b>\1</b>')
        .gsub(/\*(.+?)\*/, '<i>\1</i>')
        .gsub(/`(.+?)`/, '<code>\1</code>')
        .gsub(/\[(.+?)\]\((.+?)\)/, '<a href="\2">\1</a>')
    end

    def make_request(method, params = {})
      uri = URI("https://api.telegram.org/bot#{@bot.bot_token}/#{method}")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = params.to_json
      
      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError => e
      { 'ok' => false, 'description' => e.message }
    end
  end
end
