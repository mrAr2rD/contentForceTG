# frozen_string_literal: true

module Telegram
  class AuthService
    PYTHON_SERVICE_URL = ENV.fetch("TELEGRAM_PARSER_URL", "http://localhost:8000")

    def send_code(phone_number)
      response = make_request("/auth/send-code", {
        phone_number: phone_number
      })

      if response[:success]
        {
          success: true,
          phone_code_hash: response[:phone_code_hash]
        }
      else
        {
          success: false,
          error: response[:error] || "Ошибка отправки кода"
        }
      end
    end

    def verify_code(phone_number, phone_code_hash, phone_code)
      response = make_request("/auth/verify-code", {
        phone_number: phone_number,
        phone_code_hash: phone_code_hash,
        phone_code: phone_code
      })

      if response[:success]
        {
          success: true,
          session_string: response[:session_string]
        }
      elsif response[:requires_2fa]
        {
          success: false,
          requires_2fa: true
        }
      else
        {
          success: false,
          error: response[:error] || "Неверный код"
        }
      end
    end

    def verify_2fa(phone_number, password)
      response = make_request("/auth/verify-2fa", {
        phone_number: phone_number,
        password: password
      })

      if response[:success]
        {
          success: true,
          session_string: response[:session_string]
        }
      else
        {
          success: false,
          error: response[:error] || "Неверный пароль 2FA"
        }
      end
    end

    private

    def make_request(path, body)
      uri = URI.parse("#{PYTHON_SERVICE_URL}#{path}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request.body = body.to_json

      response = http.request(request)

      JSON.parse(response.body, symbolize_names: true)
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error "Telegram Auth Service timeout: #{e.message}"
      { success: false, error: "Сервис недоступен, попробуйте позже" }
    rescue JSON::ParserError => e
      Rails.logger.error "Telegram Auth Service parse error: #{e.message}"
      { success: false, error: "Ошибка обработки ответа" }
    rescue StandardError => e
      Rails.logger.error "Telegram Auth Service error: #{e.class} - #{e.message}"
      { success: false, error: "Ошибка сервиса авторизации" }
    end
  end
end
