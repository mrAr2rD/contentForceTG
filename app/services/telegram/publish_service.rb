require 'ostruct'
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

      result = case @post.post_type
      when 'text'
        send_text_message
      when 'image', 'image_button'
        send_photo_message
      else
        send_text_message
      end

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

    def send_text_message
      params = {
        chat_id: @bot.channel_id,
        text: format_content(@post.content),
        parse_mode: 'HTML'
      }

      # Добавляем кнопку если есть и URL валиден (для текстовых постов с кнопкой)
      if @post.respond_to?(:button_text) && @post.button_text.present? && @post.button_url.present?
        params[:reply_markup] = {
          inline_keyboard: [[
            { text: @post.button_text, url: @post.button_url }
          ]]
        }
      end

      make_request('sendMessage', params)
    end

    def send_photo_message
      # Если картинка не прикреплена или файл недоступен - публикуем как текст
      unless @post.image.attached? && image_file_exists?
        Rails.logger.warn "Post #{@post.id}: Image not available, falling back to text message"
        return send_text_message
      end

      params = {
        chat_id: @bot.channel_id,
        caption: format_content(@post.content),
        parse_mode: 'HTML'
      }

      # Добавляем кнопку для image_button типа (только если URL валиден)
      if @post.post_type == 'image_button' && @post.button_text.present? && @post.button_url.present?
        params[:reply_markup] = {
          inline_keyboard: [[
            { text: @post.button_text, url: @post.button_url }
          ]]
        }
      end

      make_multipart_request('sendPhoto', params, @post.image)
    end

    # Проверяем физическое наличие файла
    def image_file_exists?
      return false unless @post.image.attached?

      @post.image.blob.open { |f| true }
      true
    rescue ActiveStorage::FileNotFoundError
      false
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

    def make_multipart_request(method, params, image_attachment)
      uri = URI("https://api.telegram.org/bot#{@bot.bot_token}/#{method}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60 # Longer timeout for image uploads

      boundary = "----RubyMultipartPost#{rand(1000000)}"
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"

      # Build multipart body with explicit binary encoding
      body_parts = []

      # Add regular parameters with binary encoding
      params.each do |key, value|
        next if value.nil?

        if value.is_a?(Hash)
          body_parts << "--#{boundary}\r\n".force_encoding('BINARY')
          body_parts << "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n".force_encoding('BINARY')
          body_parts << "#{value.to_json}\r\n".force_encoding('BINARY')
        else
          body_parts << "--#{boundary}\r\n".force_encoding('BINARY')
          body_parts << "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n".force_encoding('BINARY')
          body_parts << "#{value}\r\n".force_encoding('BINARY')
        end
      end

      # Add image file
      image_attachment.blob.open do |file|
        body_parts << "--#{boundary}\r\n".force_encoding('BINARY')
        body_parts << "Content-Disposition: form-data; name=\"photo\"; filename=\"#{image_attachment.filename}\"\r\n".force_encoding('BINARY')
        body_parts << "Content-Type: #{image_attachment.content_type}\r\n\r\n".force_encoding('BINARY')
        body_parts << file.read.force_encoding('BINARY')
        body_parts << "\r\n".force_encoding('BINARY')
      end

      body_parts << "--#{boundary}--\r\n".force_encoding('BINARY')

      request.body = body_parts.join

      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError => e
      { 'ok' => false, 'description' => e.message }
    end
  end
end
