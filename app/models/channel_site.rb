# frozen_string_literal: true

class ChannelSite < ApplicationRecord
  # Константы
  THEMES = %w[default dark light minimal].freeze
  RESERVED_SUBDOMAINS = %w[www app api admin blog help support docs status].freeze

  # Associations
  belongs_to :telegram_bot
  belongs_to :project
  has_many :channel_posts, dependent: :destroy

  # Validations
  validates :subdomain, uniqueness: true, allow_blank: true,
    format: { with: /\A[a-z0-9][a-z0-9-]*[a-z0-9]\z/i, message: "должен содержать только буквы, цифры и дефисы" },
    length: { minimum: 3, maximum: 63 },
    exclusion: { in: RESERVED_SUBDOMAINS, message: "зарезервирован" },
    if: -> { subdomain.present? }

  validates :custom_domain, uniqueness: true, allow_blank: true,
    format: { with: /\A[a-z0-9][a-z0-9.-]*\.[a-z]{2,}\z/i, message: "должен быть валидным доменом" },
    if: -> { custom_domain.present? }

  validates :site_title, length: { maximum: 100 }, allow_blank: true
  validates :site_description, length: { maximum: 500 }, allow_blank: true
  validates :meta_title, length: { maximum: 70 }, allow_blank: true
  validates :meta_description, length: { maximum: 160 }, allow_blank: true
  validates :theme, inclusion: { in: THEMES }

  validate :must_have_domain
  validate :bot_must_be_verified
  validate :bot_must_be_channel_admin

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
  scope :by_subdomain, ->(subdomain) { where(subdomain: subdomain) }
  scope :by_custom_domain, ->(domain) { where(custom_domain: domain) }
  scope :needs_sync, -> { where("last_synced_at IS NULL OR last_synced_at < ?", 1.hour.ago) }

  # Callbacks
  before_validation :normalize_subdomain
  before_validation :normalize_custom_domain
  before_create :generate_verification_token

  # Найти сайт по хосту (subdomain или custom domain)
  def self.find_by_host(host)
    # Проверяем кастомный домен
    site = by_custom_domain(host).enabled.first
    return site if site

    # Извлекаем subdomain из хоста
    subdomain = extract_subdomain(host)
    return nil unless subdomain

    by_subdomain(subdomain).enabled.first
  end

  def self.extract_subdomain(host)
    return nil if host.blank?

    parts = host.split(".")
    # Ожидаем формат: subdomain.contentforce.ru
    return nil if parts.length < 3

    subdomain = parts.first
    return nil if subdomain.in?(RESERVED_SUBDOMAINS)

    subdomain
  end

  # Полный URL сайта
  def full_url
    "https://#{host}"
  end

  # Хост для сайта
  def host
    if custom_domain.present? && custom_domain_verified?
      custom_domain
    elsif subdomain.present?
      "#{subdomain}.#{base_domain}"
    end
  end

  # Базовый домен
  def base_domain
    Rails.application.config.action_controller.default_url_options&.dig(:host) || "contentforce.ru"
  end

  # SEO методы
  def seo_title
    meta_title.presence || site_title.presence || telegram_bot.channel_name
  end

  def seo_description
    meta_description.presence || site_description.presence || "Контент канала #{telegram_bot.channel_name}"
  end

  # Telegram ссылка
  def telegram_url
    # channel_id может быть в формате @username или -100123456789
    channel_id = telegram_bot.channel_id
    if channel_id.present?
      if channel_id.start_with?("@")
        "https://t.me/#{channel_id.delete('@')}"
      elsif telegram_bot.channel_name.present?
        # Если channel_id числовой, используем channel_name как fallback
        nil
      end
    end
  end

  # Включить сайт
  def enable!
    update!(enabled: true)
  end

  # Выключить сайт
  def disable!
    update!(enabled: false)
  end

  # Проверка домена верифицирована
  def domain_verified?
    custom_domain_verified?
  end

  # Обновить счётчик постов
  def update_posts_count!
    update_column(:posts_count, channel_posts.published.count)
  end

  private

  def must_have_domain
    if subdomain.blank? && custom_domain.blank?
      errors.add(:base, "Необходимо указать subdomain или custom_domain")
    end
  end

  def bot_must_be_verified
    return if telegram_bot.blank?

    unless telegram_bot.verified?
      errors.add(:telegram_bot, "должен быть верифицирован. Сначала подтвердите бота в настройках проекта.")
    end
  end

  def bot_must_be_channel_admin
    return if telegram_bot.blank?

    unless telegram_bot.can_create_channel_site?
      errors.add(:telegram_bot, "должен быть администратором канала с правом публикации сообщений")
    end
  end

  def normalize_subdomain
    return if subdomain.blank?

    self.subdomain = subdomain.downcase.strip
  end

  def normalize_custom_domain
    return if custom_domain.blank?

    self.custom_domain = custom_domain.downcase.strip.gsub(%r{\Ahttps?://}, "").gsub(%r{/.*\z}, "")
  end

  def generate_verification_token
    self.domain_verification_token ||= SecureRandom.hex(16)
  end
end
