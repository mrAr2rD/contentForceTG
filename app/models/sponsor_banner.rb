class SponsorBanner < ApplicationRecord
  # Active Storage для иконки/логотипа
  has_one_attached :icon

  # Явное объявление типа атрибута для enum (требование Rails 8.1)
  attribute :display_on, :integer
  attribute :label_type, :integer

  # Enum для выбора места отображения
  # public_pages: 0 - Публичные страницы (home, about, pricing и т.д.)
  # dashboard: 1 - Личный кабинет (dashboard)
  enum :display_on, { public_pages: 0, dashboard: 1 }

  # Enum для типа лейбла
  # sponsor: 0 - Спонсор (желтый)
  # support: 1 - Поддержка (зеленый)
  # partner: 2 - Партнер (синий)
  # useful: 3 - Полезное (фиолетовый)
  enum :label_type, { sponsor: 0, support: 1, partner: 2, useful: 3 }

  # Валидации
  validates :title, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 200 }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :display_on, presence: true
  validates :label_type, presence: true

  # Валидация иконки через callback (content_type и size валидаторы не поддерживаются в Rails 8.1)
  validate :validate_icon_attachment, if: -> { icon.attached? }

  def validate_icon_attachment
    return unless icon.attached?

    # Проверка content_type
    allowed_types = %w[image/png image/jpg image/jpeg image/webp image/svg+xml]
    unless allowed_types.include?(icon.content_type)
      errors.add(:icon, "должна быть изображением (PNG, JPG, WEBP или SVG)")
    end

    # Проверка размера
    if icon.byte_size > 1.megabyte
      errors.add(:icon, "должна быть меньше 1MB")
    end
  end

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :active, -> { enabled.order(created_at: :desc).first }
  scope :for_public, -> { where(display_on: :public_pages) }
  scope :for_dashboard, -> { where(display_on: :dashboard) }

  # Singleton pattern - только один активный баннер на каждое место отображения
  # Автоматически отключаем другие баннеры при активации нового
  before_save :disable_other_banners, if: :enabled?

  # Класс-метод для получения активного баннера
  # @param location [Symbol] :public_pages или :dashboard
  def self.current(location = :public_pages)
    enabled.where(display_on: location).order(created_at: :desc).first
  end

  # Человекочитаемое название места отображения
  def display_on_label
    case display_on
    when "public_pages"
      "Публичные страницы"
    when "dashboard"
      "Личный кабинет"
    else
      display_on.humanize
    end
  end

  # Текст лейбла для отображения
  def label_text
    case label_type
    when "sponsor" then "Спонсор"
    when "support" then "Поддержка"
    when "partner" then "Партнёр"
    when "useful" then "Полезное"
    else "Спонсор"
    end
  end

  # CSS классы для цвета лейбла (Tailwind)
  def label_color_classes
    case label_type
    when "sponsor" then "bg-yellow-500/10 text-yellow-500"      # Желтый
    when "support" then "bg-emerald-500/10 text-emerald-500"    # Зеленый
    when "partner" then "bg-blue-500/10 text-blue-500"          # Синий
    when "useful" then "bg-purple-500/10 text-purple-500"       # Фиолетовый
    else "bg-yellow-500/10 text-yellow-500"
    end
  end

  private

  def disable_other_banners
    return unless enabled_changed? && enabled?

    # Отключаем другие баннеры только для того же места отображения
    SponsorBanner.where.not(id: id)
                 .where(display_on: display_on)
                 .update_all(enabled: false)
  end
end
