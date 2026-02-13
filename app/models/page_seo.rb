# frozen_string_literal: true

class PageSeo < ApplicationRecord
  # Список доступных публичных страниц
  PAGES = {
    "home" => "Главная",
    "about" => "О нас",
    "contacts" => "Контакты",
    "careers" => "Партнёрская программа",
    "docs" => "Документация",
    "privacy" => "Политика конфиденциальности",
    "terms" => "Публичная оферта",
    "blog" => "Блог"
  }.freeze

  # Валидации
  validates :slug, presence: true, uniqueness: true, inclusion: { in: PAGES.keys }
  validates :title, length: { maximum: 70 }, allow_blank: true
  validates :description, length: { maximum: 160 }, allow_blank: true
  validates :og_title, length: { maximum: 70 }, allow_blank: true
  validates :og_description, length: { maximum: 200 }, allow_blank: true

  # Scopes
  scope :ordered, -> { order(:slug) }
  scope :indexed, -> { where(noindex: false) }
  scope :noindexed, -> { where(noindex: true) }

  # Получить SEO для страницы (с fallback на дефолтные значения)
  def self.for_page(slug)
    find_by(slug: slug)
  end

  # Название страницы для отображения в админке
  def page_name
    PAGES[slug] || slug.humanize
  end

  # Полный title с названием сайта
  def full_title
    site_name = SiteConfiguration.current.site_name.presence || "ContentForce"
    "#{title} — #{site_name}"
  end

  # OG title с fallback на обычный title
  def effective_og_title
    og_title.presence || title
  end

  # OG description с fallback на обычный description
  def effective_og_description
    og_description.presence || description
  end

  # Создать дефолтные записи для всех страниц
  def self.seed_defaults!
    defaults = {
      "home" => {
        title: "Контент для Telegram за минуты с AI",
        description: "Создавайте, планируйте и публикуйте контент в Telegram автоматически с помощью AI. Бесплатно для новых пользователей."
      },
      "about" => {
        title: "О нас",
        description: "ContentForce — платформа для автоматизации создания и публикации контента в Telegram с использованием AI."
      },
      "contacts" => {
        title: "Контакты",
        description: "Свяжитесь с командой ContentForce. Мы готовы помочь с вопросами по продукту."
      },
      "careers" => {
        title: "Партнёрская программа",
        description: "Станьте партнёром ContentForce и зарабатывайте 20% с каждого привлечённого клиента."
      },
      "docs" => {
        title: "Документация",
        description: "Руководство пользователя ContentForce. Создание проектов, подключение Telegram-ботов, генерация контента с AI."
      },
      "privacy" => {
        title: "Политика конфиденциальности",
        description: "Как мы обрабатываем и защищаем персональные данные пользователей в соответствии с ФЗ №152."
      },
      "terms" => {
        title: "Публичная оферта",
        description: "Условия использования SaaS-платформы ContentForce. Договор с пользователем."
      },
      "blog" => {
        title: "Блог",
        description: "Статьи о контент-маркетинге, AI и автоматизации Telegram-каналов."
      }
    }

    defaults.each do |slug, attrs|
      find_or_create_by!(slug: slug) do |seo|
        seo.title = attrs[:title]
        seo.description = attrs[:description]
      end
    end
  end
end
