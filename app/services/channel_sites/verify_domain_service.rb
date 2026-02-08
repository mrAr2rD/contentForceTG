# frozen_string_literal: true

require "resolv"

module ChannelSites
  class VerifyDomainService
    def initialize(channel_site)
      @channel_site = channel_site
    end

    def call
      return { success: false, error: "Кастомный домен не указан" } if @channel_site.custom_domain.blank?
      return { success: true } if @channel_site.custom_domain_verified?

      if verify_dns_record
        @channel_site.update!(custom_domain_verified: true)
        { success: true }
      else
        { success: false, error: "DNS TXT запись не найдена или неверна" }
      end
    rescue StandardError => e
      Rails.logger.error("VerifyDomainService error: #{e.message}")
      { success: false, error: e.message }
    end

    private

    def verify_dns_record
      expected_value = "contentforce-verify=#{@channel_site.domain_verification_token}"

      # Проверяем TXT записи домена
      txt_records = fetch_txt_records(@channel_site.custom_domain)

      txt_records.any? { |record| record.include?(expected_value) }
    end

    def fetch_txt_records(domain)
      resolver = Resolv::DNS.new

      records = resolver.getresources(domain, Resolv::DNS::Resource::IN::TXT)
      records.map { |r| r.strings.join }
    rescue Resolv::ResolvError
      []
    ensure
      resolver.close
    end
  end
end
