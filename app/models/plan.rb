# frozen_string_literal: true

# Модель тарифного плана
# Хранит цены, лимиты и фичи для каждого тарифа
class Plan < ApplicationRecord
  has_many :subscriptions, dependent: :nullify

  # Валидации
  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc) }
  scope :for_display, -> { active.ordered }

  # Callbacks для инвалидации кэша
  after_save :invalidate_cache!
  after_destroy :invalidate_cache!

  CACHE_KEY = "plans/all"
  CACHE_TTL = 1.hour

  # =============================================================================
  # Кэширование
  # =============================================================================

  # Кэшированный список всех активных планов
  def self.cached_all
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      for_display.to_a
    end
  end

  # Кэшированный поиск по slug
  def self.cached_find_by_slug(slug)
    cached_all.find { |plan| plan.slug == slug.to_s }
  end

  # Инвалидация кэша
  def self.invalidate_cache!
    Rails.cache.delete(CACHE_KEY)
  end

  # Возвращает план по slug (deprecated, используйте cached_find_by_slug)
  def self.find_by_slug(slug)
    find_by(slug: slug)
  end

  # =============================================================================
  # Стандартные планы для seed с маркетинговыми данными
  # =============================================================================
  DEFAULTS = {
    free: {
      name: "Бесплатный",
      price: 0,
      position: 0,
      limits: {
        projects: 1,
        bots: 1,
        posts_per_month: 10,
        ai_generations_per_month: 5
      },
      features: {
        analytics: "basic",
        tagline: "Для знакомства",
        description: "Начните бесплатно и оцените возможности платформы",
        popular: false,
        badge: nil
      }
    },
    starter: {
      name: "Starter",
      price: 590,
      position: 1,
      limits: {
        projects: 3,
        bots: 3,
        posts_per_month: 100,
        ai_generations_per_month: 50
      },
      features: {
        analytics: "full",
        tagline: "Для соло-предпринимателей",
        description: "Идеально для начинающих контент-мейкеров",
        popular: true,
        badge: "Популярный",
        email_support: true
      }
    },
    pro: {
      name: "Pro",
      price: 1490,
      position: 2,
      limits: {
        projects: 10,
        bots: 10,
        posts_per_month: -1,
        ai_generations_per_month: 500,
        ai_image_generations_per_month: 20
      },
      features: {
        analytics: "advanced",
        tagline: "Для растущего бизнеса",
        description: "Расширенные возможности для профессионалов",
        popular: false,
        badge: nil,
        priority_support: true,
        api_access: true
      }
    },
    business: {
      name: "Business",
      price: 2990,
      position: 3,
      limits: {
        projects: -1,
        bots: -1,
        posts_per_month: -1,
        ai_generations_per_month: -1,
        ai_image_generations_per_month: 100
      },
      features: {
        analytics: "premium",
        tagline: "Для команд и агентств",
        description: "Полный контроль и безлимитные возможности",
        popular: false,
        badge: "Enterprise",
        priority_support: true,
        personal_manager: true,
        customization: true,
        multichannel: true
      }
    }
  }.freeze

  # =============================================================================
  # Методы форматирования для views
  # =============================================================================

  # Форматированная цена: "590₽" или "Бесплатно"
  def formatted_price
    free? ? "Бесплатно" : "#{price.to_i}₽"
  end

  # Форматированный лимит: "∞" для безлимитных или число
  def formatted_limit(feature)
    value = limit_for(feature)
    value == Float::INFINITY ? "∞" : value.to_s
  end

  # Описание лимита: "3 проекта" / "Безлимит проектов"
  def limit_description(feature, singular: nil, plural: nil)
    value = limit_for(feature)
    if value == Float::INFINITY
      "Безлимит #{plural || feature.to_s}"
    else
      word = value == 1 ? (singular || feature.to_s) : (plural || feature.to_s)
      "#{value} #{word}"
    end
  end

  # Маркетинговое описание плана
  def description
    features&.dig("description") || DEFAULTS.dig(slug.to_sym, :features, :description) || ""
  end

  # Короткий слоган плана
  def tagline
    features&.dig("tagline") || DEFAULTS.dig(slug.to_sym, :features, :tagline) || ""
  end

  # Популярный ли план (для выделения)
  def popular?
    features&.dig("popular") == true || DEFAULTS.dig(slug.to_sym, :features, :popular) == true
  end

  # Текст бейджа (nil если нет)
  def badge_text
    features&.dig("badge") || DEFAULTS.dig(slug.to_sym, :features, :badge)
  end

  # =============================================================================
  # Базовые методы
  # =============================================================================

  # Возвращает лимит для конкретной фичи
  def limit_for(feature)
    value = limits&.dig(feature.to_s) || limits&.dig(feature.to_sym)
    return Float::INFINITY if value == -1
    value || 0
  end

  # Проверяет, есть ли фича
  def feature?(feature)
    features&.dig(feature.to_s) || features&.dig(feature.to_sym)
  end

  # Бесплатный ли план
  def free?
    price.to_f.zero?
  end

  # Безлимитный ли лимит
  def unlimited?(feature)
    limit_for(feature) == Float::INFINITY
  end

  # Уровень аналитики
  def analytics_level
    features&.dig("analytics") || "basic"
  end

  # Уровень аналитики для отображения
  def analytics_level_name
    case analytics_level
    when "basic" then "Базовая"
    when "full" then "Полная"
    when "advanced" then "Расширенная"
    when "premium" then "Премиум"
    else analytics_level.to_s.titleize
    end
  end

  private

  def invalidate_cache!
    self.class.invalidate_cache!
  end
end
