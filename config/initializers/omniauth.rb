# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :telegram,
           ENV.fetch("TELEGRAM_BOT_TOKEN", nil),
           origin_url: ENV.fetch("TELEGRAM_ORIGIN_URL", "http://localhost:3001")
end

# Configure OmniAuth
OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true
