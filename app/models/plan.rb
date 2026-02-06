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

  # Возвращает план по slug
  def self.find_by_slug(slug)
    find_by(slug: slug)
  end

  # Стандартные планы для seed
  DEFAULTS = {
    free: {
      name: 'Бесплатный',
      price: 0,
      position: 0,
      limits: {
        projects: 1,
        bots: 1,
        posts_per_month: 10,
        ai_generations_per_month: 5 # Только для платных моделей
      },
      features: {
        analytics: 'basic'
      }
    },
    starter: {
      name: 'Starter',
      price: 590,
      position: 1,
      limits: {
        projects: 3,
        bots: 3,
        posts_per_month: 100,
        ai_generations_per_month: 50
      },
      features: {
        analytics: 'full'
      }
    },
    pro: {
      name: 'Pro',
      price: 1490,
      position: 2,
      limits: {
        projects: 10,
        bots: 10,
        posts_per_month: -1, # unlimited
        ai_generations_per_month: 500,
        ai_image_generations_per_month: 20
      },
      features: {
        analytics: 'advanced'
      }
    },
    business: {
      name: 'Business',
      price: 2990,
      position: 3,
      limits: {
        projects: -1, # unlimited
        bots: -1,
        posts_per_month: -1,
        ai_generations_per_month: -1,
        ai_image_generations_per_month: 100
      },
      features: {
        analytics: 'premium',
        priority_support: true
      }
    }
  }.freeze

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
    features&.dig('analytics') || 'basic'
  end
end
