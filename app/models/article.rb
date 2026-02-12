# frozen_string_literal: true

class Article < ApplicationRecord
  # Concerns
  include ImageValidatable

  # Таблица транслитерации кириллицы
  TRANSLIT_MAP = {
    'а' => 'a', 'б' => 'b', 'в' => 'v', 'г' => 'g', 'д' => 'd', 'е' => 'e', 'ё' => 'yo',
    'ж' => 'zh', 'з' => 'z', 'и' => 'i', 'й' => 'y', 'к' => 'k', 'л' => 'l', 'м' => 'm',
    'н' => 'n', 'о' => 'o', 'п' => 'p', 'р' => 'r', 'с' => 's', 'т' => 't', 'у' => 'u',
    'ф' => 'f', 'х' => 'h', 'ц' => 'ts', 'ч' => 'ch', 'ш' => 'sh', 'щ' => 'sch', 'ъ' => '',
    'ы' => 'y', 'ь' => '', 'э' => 'e', 'ю' => 'yu', 'я' => 'ya'
  }.freeze

  # Категории статей
  CATEGORIES = %w[product tutorials updates tips case-studies].freeze

  # Associations
  belongs_to :author, class_name: 'User'
  has_one_attached :cover_image

  # Enums
  enum :status, { draft: 0, published: 1 }, default: :draft

  # Validations
  validates :title, presence: true, length: { minimum: 5, maximum: 200 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/, message: 'допускает только строчные буквы, цифры и дефисы' }
  validates :content, presence: true, length: { minimum: 50 }
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true
  validates :excerpt, length: { maximum: 500 }, allow_blank: true
  validates :meta_title, length: { maximum: 70 }, allow_blank: true
  validates :meta_description, length: { maximum: 160 }, allow_blank: true
  validate :validate_cover_image, if: -> { cover_image.attached? }

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  before_save :calculate_reading_time, if: -> { content_changed? }
  before_save :set_published_at, if: -> { published? && published_at.blank? }

  # Scopes
  scope :published, -> { where(status: :published).where('published_at IS NOT NULL AND published_at <= ?', Time.current) }
  scope :recent, -> { order(Arel.sql('COALESCE(published_at, created_at) DESC')) }
  scope :by_category, ->(category) { where(category: category) }
  scope :featured, -> { published.recent.limit(3) }

  # Использовать slug вместо id в URL
  def to_param
    slug
  end

  # Увеличить счётчик просмотров
  def increment_views!
    increment!(:views_count)
  end

  # Рассчитать время чтения (средняя скорость 200 слов/мин для русского)
  def calculate_reading_time
    return unless content.present?

    words = content.split.size
    self.reading_time = (words / 200.0).ceil
  end

  # Опубликовать статью
  def publish!
    update!(status: :published, published_at: Time.current)
  end

  # Снять с публикации
  def unpublish!
    update!(status: :draft, published_at: nil)
  end

  # Meta title для SEO
  def seo_title
    meta_title.presence || title
  end

  # Meta description для SEO
  def seo_description
    meta_description.presence || excerpt.presence || content.truncate(160)
  end

  private

  # Валидация обложки с проверкой magic bytes
  def validate_cover_image
    validate_image_attachment(
      cover_image,
      field_name: :cover_image,
      allowed_types: %w[image/jpeg image/png image/webp],
      max_size: 5.megabytes
    )
  end

  def set_published_at
    self.published_at = Time.current
  end

  def generate_slug
    # Транслитерация кириллицы
    transliterated = title.downcase.chars.map { |char| TRANSLIT_MAP[char] || char }.join
    # Очистка и форматирование
    self.slug = transliterated
                .gsub(/[^a-z0-9\s-]/, '')
                .gsub(/[\s_]+/, '-')
                .gsub(/-+/, '-')
                .gsub(/^-|-$/, '')
    # Если slug пустой, генерируем из timestamp
    self.slug = "article-#{Time.current.to_i}" if slug.blank?
  end
end
