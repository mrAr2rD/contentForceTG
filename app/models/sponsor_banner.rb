class SponsorBanner < ApplicationRecord
  # Active Storage для иконки/логотипа
  has_one_attached :icon

  # Валидации
  validates :title, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 200 }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :icon, content_type: { in: %w[image/png image/jpg image/jpeg image/webp image/svg+xml],
                                   message: "должна быть изображением" },
                   size: { less_than: 1.megabyte, message: "должна быть меньше 1MB" },
                   if: -> { icon.attached? }

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :active, -> { enabled.order(created_at: :desc).first }

  # Singleton pattern - только один активный баннер
  # Автоматически отключаем другие баннеры при активации нового
  before_save :disable_other_banners, if: :enabled?

  # Класс-метод для получения активного баннера
  def self.current
    active
  end

  private

  def disable_other_banners
    return unless enabled_changed? && enabled?

    SponsorBanner.where.not(id: id).update_all(enabled: false)
  end
end
