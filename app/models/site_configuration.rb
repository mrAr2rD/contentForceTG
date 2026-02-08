# frozen_string_literal: true

class SiteConfiguration < ApplicationRecord
  # Singleton pattern - только одна конфигурация
  def self.current
    first_or_create!(channel_sites_enabled: false, analytics_enabled: true, telegram_integration_enabled: false)
  end

  # Проверка включён ли функционал мини-сайтов
  def self.channel_sites_enabled?
    current.channel_sites_enabled?
  end

  # Проверка включён ли функционал аналитики
  def self.analytics_enabled?
    current.analytics_enabled?
  end

  # Проверка включена ли Telegram интеграция (авторизация через Pyrogram)
  def self.telegram_integration_enabled?
    current.telegram_integration_enabled?
  end
end
