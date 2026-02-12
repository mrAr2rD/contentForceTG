# frozen_string_literal: true

# Настройка session store с безопасными cookie флагами
Rails.application.config.session_store :cookie_store,
  key: "_contentforce_session",
  expire_after: 2.weeks,
  secure: Rails.env.production?,  # HTTPS only в production
  httponly: true,                  # Защита от XSS
  same_site: :lax                  # Защита от CSRF
