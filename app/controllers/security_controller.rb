# frozen_string_literal: true

class SecurityController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :csp_report ]
  skip_before_action :authenticate_user!, only: [ :csp_report ], raise: false

  def csp_report
    begin
      report = JSON.parse(request.body.read)
      csp_report = report["csp-report"]

      Rails.logger.warn(
        "CSP Violation: " \
        "blocked-uri=#{csp_report['blocked-uri']} " \
        "violated-directive=#{csp_report['violated-directive']} " \
        "document-uri=#{csp_report['document-uri']}"
      )

      # В production отправляем в Sentry для мониторинга
      if Rails.env.production? && defined?(Sentry)
        Sentry.capture_message(
          "CSP Violation",
          level: :warning,
          extra: { csp_report: csp_report }
        )
      end

      head :ok
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse CSP report: #{e.message}")
      head :bad_request
    rescue StandardError => e
      Rails.logger.error("CSP report error: #{e.message}")
      head :internal_server_error
    end
  end
end
