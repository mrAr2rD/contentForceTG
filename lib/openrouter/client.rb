# frozen_string_literal: true

require 'net/http'
require 'json'

module Openrouter
  class Client
    BASE_URL = 'https://openrouter.ai/api/v1'

    def initialize(api_key: nil)
      # Используем API ключ из параметра, админки или ENV
      @api_key = api_key || AiConfiguration.current.api_key
      @site_url = ENV['OPENROUTER_SITE_URL'] || 'https://contentforce.app'
      @site_name = ENV['OPENROUTER_SITE_NAME'] || 'ContentForce'
    end

    def chat(model:, messages:, temperature: 0.7, max_tokens: 2000, **options)
      raise ConfigurationError, 'OpenRouter API key not configured' unless @api_key.present?

      uri = URI("#{BASE_URL}/chat/completions")
      request = build_request(uri, {
        model: model,
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens,
        **options
      })

      response = execute_request(uri, request)
      parse_response(response)
    rescue StandardError => e
      handle_error(e)
    end

    # Генерация изображений через OpenRouter API
    # Использует modalities: ["image"] для моделей с поддержкой генерации изображений
    def generate_image(model:, prompt:, aspect_ratio: '1:1')
      raise ConfigurationError, 'OpenRouter API key not configured' unless @api_key.present?

      uri = URI("#{BASE_URL}/chat/completions")

      # Формируем запрос с указанием модальности изображения
      body = {
        model: model,
        messages: [
          { role: 'user', content: prompt }
        ],
        modalities: [ 'image' ],
        response_format: {
          type: 'image'
        }
      }

      # Добавляем параметры генерации в зависимости от модели
      if model.include?('flux')
        # Flux модели поддерживают aspect_ratio напрямую
        body[:extra_body] = { aspect_ratio: aspect_ratio }
      end

      request = build_request(uri, body)

      # Увеличиваем таймаут для генерации изображений (до 2 минут)
      response = execute_request(uri, request, timeout: 120)
      parse_image_response(response)
    rescue StandardError => e
      handle_error(e)
    end

    private

    def build_request(uri, body)
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@api_key}"
      request['HTTP-Referer'] = @site_url
      request['X-Title'] = @site_name
      request['Content-Type'] = 'application/json'
      request.body = body.to_json
      request
    end

    def execute_request(uri, request, timeout: 60)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.read_timeout = timeout
        http.open_timeout = 30
        http.request(request)
      end
    end

    def parse_response(response)
      body = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        error_message = body.dig('error', 'message') || 'Unknown error'
        raise APIError, "OpenRouter API error: #{error_message}"
      end

      {
        content: body.dig('choices', 0, 'message', 'content'),
        model: body['model'],
        usage: {
          prompt_tokens: body.dig('usage', 'prompt_tokens') || 0,
          completion_tokens: body.dig('usage', 'completion_tokens') || 0,
          total_tokens: body.dig('usage', 'total_tokens') || 0
        },
        finish_reason: body.dig('choices', 0, 'finish_reason')
      }
    end

    # Парсинг ответа с изображением
    # OpenRouter возвращает изображение в поле images внутри message
    # Формат: { choices: [{ message: { content: "...", images: [{ type: "image_url", image_url: { url: "data:..." } }] } }] }
    def parse_image_response(response)
      body = JSON.parse(response.body)

      # Логируем ответ для отладки
      Rails.logger.info "OpenRouter image response: #{body.to_json[0..500]}..."

      unless response.is_a?(Net::HTTPSuccess)
        error_message = body.dig('error', 'message') || 'Unknown error'
        raise APIError, "OpenRouter API error: #{error_message}"
      end

      message = body.dig('choices', 0, 'message')
      raise APIError, 'No message in response' unless message

      image_data = nil
      content_type = 'image/png'

      # Способ 1: Изображения в отдельном поле images (основной формат OpenRouter)
      images = message['images']
      if images.is_a?(Array) && images.any?
        image_item = images.first
        url = image_item.dig('image_url', 'url') || image_item['url']
        if url&.start_with?('data:')
          image_data, content_type = extract_base64_from_data_uri(url)
        elsif url&.match?(/^[A-Za-z0-9+\/=]+$/)
          image_data = url
        end
      end

      # Способ 2: Изображение в content как массив (альтернативный формат)
      content = message['content']
      if image_data.nil? && content.is_a?(Array)
        image_item = content.find { |item| item['type'] == 'image_url' }
        if image_item
          url = image_item.dig('image_url', 'url')
          if url&.start_with?('data:')
            image_data, content_type = extract_base64_from_data_uri(url)
          end
        end
      end

      # Способ 3: Content напрямую содержит data URI
      if image_data.nil? && content.is_a?(String) && content.start_with?('data:')
        image_data, content_type = extract_base64_from_data_uri(content)
      end

      # Способ 4: Content содержит чистый base64
      if image_data.nil? && content.is_a?(String) && content.match?(/^[A-Za-z0-9+\/=]{100,}$/)
        image_data = content
      end

      raise APIError, 'No image data in response' unless image_data

      {
        image_data: image_data,
        content_type: content_type,
        model: body['model'],
        usage: {
          prompt_tokens: body.dig('usage', 'prompt_tokens') || 0,
          completion_tokens: body.dig('usage', 'completion_tokens') || 0,
          total_tokens: body.dig('usage', 'total_tokens') || 0
        }
      }
    end

    # Извлечение base64 данных из data URI
    def extract_base64_from_data_uri(uri)
      match = uri.match(/^data:([^;]+);base64,(.+)$/m)
      return nil, 'image/png' unless match

      [ match[2], match[1] ]
    end

    def handle_error(error)
      case error
      when JSON::ParserError
        raise APIError, 'Invalid JSON response from OpenRouter'
      when Net::HTTPError
        raise APIError, "HTTP error: #{error.message}"
      when Timeout::Error
        raise APIError, 'Request timeout'
      else
        raise APIError, error.message
      end
    end
  end

  class Error < StandardError; end
  class ConfigurationError < Error; end
  class APIError < Error; end
end
