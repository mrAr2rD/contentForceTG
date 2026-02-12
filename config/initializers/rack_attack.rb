# frozen_string_literal: true

# Rack::Attack configuration для rate limiting и защиты от DDoS
# Документация: https://github.com/rack/rack-attack

class Rack::Attack
  ### Конфигурация Redis для распределённой среды ###
  # В production Rack::Attack использует Redis через Rails.cache
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"),
    namespace: "rack_attack"
  )

  ### Разрешённые IP (allowlist) ###
  # Всегда разрешаем localhost для dev/test
  Rack::Attack.safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  ### Заблокированные IP (blocklist) ###
  # Можно добавить постоянный бан: Rack::Attack.blocklist_ip("1.2.3.4")
  # Или динамически через Redis: Rails.cache.write("block:1.2.3.4", true, expires_in: 1.day)
  Rack::Attack.blocklist("block-bad-ips") do |req|
    Rails.cache.read("block:#{req.ip}")
  end

  ### Throttling Rules (Rate Limiting) ###

  # 1. Ограничение общих запросов с одного IP: 300 запросов в минуту
  throttle("req/ip", limit: 300, period: 1.minute) do |req|
    req.ip
  end

  # 2. Ограничение авторизации: 5 попыток входа в 20 секунд
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # 3. Ограничение регистрации: 3 попытки в 1 час
  throttle("signups/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/users" && req.post?
      req.ip
    end
  end

  # 4. Ограничение AI запросов: 20 в минуту на проект
  throttle("ai/project", limit: 20, period: 1.minute) do |req|
    if req.path.start_with?("/dashboard/ai/") && (req.post? || req.put? || req.patch?)
      # Извлекаем project_id из параметров или пути
      project_id = req.params["project_id"] || req.env["action_dispatch.request.path_parameters"]&.dig(:project_id)
      user_id = req.env["warden"]&.user(:user)&.id
      "#{user_id}:#{project_id}" if user_id && project_id
    end
  end

  # 5. Защита Telegram webhooks: 100 запросов в минуту на бота
  throttle("webhooks/telegram", limit: 100, period: 1.minute) do |req|
    if req.path.start_with?("/webhooks/telegram/")
      # Извлекаем bot_id из пути: /webhooks/telegram/:bot_id
      bot_id = req.path.split("/")[3]
      "telegram:#{bot_id}" if bot_id
    end
  end

  # 6. Защита Robokassa webhooks: 50 запросов в минуту
  throttle("webhooks/robokassa", limit: 50, period: 1.minute) do |req|
    if req.path.start_with?("/webhooks/robokassa")
      "robokassa:#{req.ip}"
    end
  end

  # 7. Защита API endpoints: 60 запросов в минуту на пользователя
  throttle("api/user", limit: 60, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      user_id = req.env["warden"]&.user(:user)&.id
      "api:#{user_id}" if user_id
    end
  end

  ### Custom Responses ###

  # Кастомный ответ при превышении лимита
  self.throttled_responder = lambda do |env|
    match_data = env["rack.attack.match_data"]
    now = Time.now.to_i
    period = match_data[:period]
    limit = match_data[:limit]

    # Заголовки для клиента
    headers = {
      "Content-Type" => "application/json",
      "X-RateLimit-Limit" => limit.to_s,
      "X-RateLimit-Remaining" => "0",
      "X-RateLimit-Reset" => (now + (period - (now % period))).to_s
    }

    # Определяем retry_after
    retry_after = (period - (now % period))

    # JSON ответ
    body = {
      error: "Rate limit exceeded",
      message: "Too many requests. Please try again later.",
      retry_after: retry_after
    }.to_json

    [ 429, headers, [ body ] ]
  end

  ### Exponential Backoff для повторных нарушений ###
  # После 2 бана за 10 минут — блокируем на 1 час
  Rack::Attack.blocklist("block-repeat-offenders") do |req|
    # Считаем количество бана за последние 10 минут
    if Rack::Attack::Allow2Ban.filter("repeat-offenders:#{req.ip}", maxretry: 2, findtime: 10.minutes, bantime: 1.hour) do
      # Был ли недавно throttled?
      Rails.cache.read("throttled:#{req.ip}")
    end
      true
    end
  end

  ### Логирование ###
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Throttled: #{req.ip} #{req.request_method} #{req.fullpath} (#{payload[:matched]})"

    # Отмечаем IP как throttled для exponential backoff
    Rails.cache.write("throttled:#{req.ip}", true, expires_in: 10.minutes)
  end

  ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.error "[Rack::Attack] Blocked: #{req.ip} #{req.request_method} #{req.fullpath} (#{payload[:matched]})"
  end
end
