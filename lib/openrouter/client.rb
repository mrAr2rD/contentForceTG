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

    def execute_request(uri, request)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
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
