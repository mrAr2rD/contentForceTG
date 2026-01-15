# frozen_string_literal: true

module OpenRouter
  class Client
    BASE_URL = 'https://openrouter.ai/api/v1'

    def initialize(api_key: nil)
      @api_key = api_key || ENV['OPENROUTER_API_KEY']
      raise ArgumentError, 'OpenRouter API key is required' if @api_key.blank?
    end

    def chat(params)
      response = connection.post('/chat/completions') do |req|
        req.body = build_request_body(params).to_json
      end

      handle_response(response)
    rescue Faraday::Error => e
      Rails.logger.error("OpenRouter API Error: #{e.message}")
      raise OpenRouter::Error, e.message
    end

    def models
      response = connection.get('/models')
      JSON.parse(response.body)
    rescue Faraday::Error => e
      Rails.logger.error("OpenRouter API Error: #{e.message}")
      raise OpenRouter::Error, e.message
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :json
        f.response :json
        f.response :raise_error
        f.headers['Authorization'] = "Bearer #{@api_key}"
        f.headers['HTTP-Referer'] = ENV['OPENROUTER_SITE_URL'] || 'http://localhost:3000'
        f.headers['X-Title'] = ENV['OPENROUTER_SITE_NAME'] || 'ContentForce'
        f.adapter Faraday.default_adapter
      end
    end

    def build_request_body(params)
      {
        model: params[:model],
        messages: params[:messages],
        temperature: params[:temperature] || 0.7,
        max_tokens: params[:max_tokens] || 2000,
        top_p: params[:top_p] || 1.0,
        frequency_penalty: params[:frequency_penalty] || 0,
        presence_penalty: params[:presence_penalty] || 0,
        transforms: params[:transforms] || [],
        route: params[:route] || 'fallback'
      }.compact
    end

    def handle_response(response)
      body = response.body

      {
        content: body.dig('choices', 0, 'message', 'content'),
        model: body['model'],
        usage: {
          prompt_tokens: body.dig('usage', 'prompt_tokens'),
          completion_tokens: body.dig('usage', 'completion_tokens'),
          total_tokens: body.dig('usage', 'total_tokens')
        },
        id: body['id'],
        created: body['created']
      }
    end
  end

  class Error < StandardError; end
end
