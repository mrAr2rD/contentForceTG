# frozen_string_literal: true

class SubdomainConstraint
  RESERVED_SUBDOMAINS = %w[www app api admin blog help support docs status].freeze

  def matches?(request)
    return false if request.host.blank?

    # Проверяем кастомный домен
    return true if ChannelSite.enabled.exists?(custom_domain: request.host)

    # Извлекаем subdomain
    subdomain = extract_subdomain(request.host)
    return false if subdomain.blank?
    return false if subdomain.in?(RESERVED_SUBDOMAINS)

    # Проверяем существование и активность сайта
    ChannelSite.enabled.exists?(subdomain: subdomain)
  end

  private

  def extract_subdomain(host)
    return nil if host.blank?

    parts = host.split(".")
    # Ожидаем формат: subdomain.domain.tld (минимум 3 части)
    return nil if parts.length < 3

    # Для localhost с портом: subdomain.localhost
    if host.include?("localhost")
      return parts.first if parts.length >= 2
    end

    parts.first
  end
end
