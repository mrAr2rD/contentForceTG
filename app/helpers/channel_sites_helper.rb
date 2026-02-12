# frozen_string_literal: true

module ChannelSitesHelper
  # Безопасная обработка кастомного CSS
  # Блокирует опасные конструкции перед рендерингом
  def sanitize_custom_css(css)
    return "" if css.blank?

    # Опасные паттерны для блокировки
    dangerous_patterns = [
      /@import/i,
      /url\s*\(/i,
      /javascript:/i,
      /expression\s*\(/i,
      /<script/i,
      /on\w+\s*=/i  # onclick=, onload=, etc.
    ]

    # Проверяем на наличие опасных конструкций
    dangerous_patterns.each do |pattern|
      if css.match?(pattern)
        Rails.logger.warn("SECURITY: Blocked dangerous CSS pattern: #{pattern.inspect}")
        return "/* Заблокирован небезопасный CSS */"
      end
    end

    # Возвращаем как raw HTML (уже прошло проверку)
    raw(css)
  end
end
