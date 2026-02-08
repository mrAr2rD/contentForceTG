# frozen_string_literal: true

class SiteConfiguration < ApplicationRecord
  # Singleton pattern - только одна конфигурация
  def self.current
    first_or_create!(channel_sites_enabled: false)
  end

  # Проверка включён ли функционал мини-сайтов
  def self.channel_sites_enabled?
    current.channel_sites_enabled?
  end
end
