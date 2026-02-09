# frozen_string_literal: true

class ImportStyleSamplesJob < ApplicationJob
  queue_as :default

  PYTHON_SERVICE_URL = ENV.fetch("TELEGRAM_PARSER_URL", "http://localhost:8000")

  def perform(project_id:, telegram_session_id:, channel_username:, limit: 100)
    project = Project.find_by(id: project_id)
    telegram_session = TelegramSession.find_by(id: telegram_session_id)

    return unless project && telegram_session&.auth_auth_active?

    # Формируем callback URL
    callback_url = Rails.application.routes.url_helpers.webhooks_style_import_url(
      host: ENV.fetch("APP_HOST", "localhost:3000"),
      protocol: Rails.env.production? ? "https" : "http"
    )

    # Вызываем Python microservice
    response = make_sync_request(
      session_string: telegram_session.session_string,
      channel_username: channel_username,
      limit: limit,
      import_type: "style_samples",
      project_id: project.id,
      callback_url: callback_url
    )

    if response[:status] == "started"
      Rails.logger.info "Style samples import started for project #{project_id}, channel #{channel_username}"
    else
      Rails.logger.error "Style samples import failed: #{response[:error] || response[:detail] || response.inspect}"
    end
  end

  private

  def make_sync_request(params)
    uri = URI.parse("#{PYTHON_SERVICE_URL}/sync")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request.body = params.to_json

    response = http.request(request)

    JSON.parse(response.body, symbolize_names: true)
  rescue StandardError => e
    Rails.logger.error "Import style samples request failed: #{e.message}"
    { success: false, error: e.message }
  end
end
