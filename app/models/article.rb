# frozen_string_literal: true

class Article < ApplicationRecord
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
  validates :content, presence: true, length: { minimum: 100 }
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true
  validates :excerpt, length: { maximum: 500 }, allow_blank: true
  validates :meta_title, length: { maximum: 70 }, allow_blank: true
  validates :meta_description, length: { maximum: 160 }, allow_blank: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  before_save :calculate_reading_time, if: -> { content_changed? }

  # Scopes
  scope :published, -> { where(status: :published).where('published_at <= ?', Time.current) }
  scope :recent, -> { order(published_at: :desc) }
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

  def generate_slug
    self.slug = Russian.translit(title)
                       .downcase
                       .gsub(/[^a-z0-9\s-]/, '')
                       .gsub(/[\s_]+/, '-')
                       .gsub(/-+/, '-')
                       .gsub(/^-|-$/, '')
  rescue StandardError
    # Если gem russian не установлен, используем простую транслитерацию
    self.slug = title
                .downcase
                .gsub(/[^a-z0-9\s-]/, '')
                .gsub(/[\s_]+/, '-')
                .gsub(/-+/, '-')
                .gsub(/^-|-$/, '')
  end
end
