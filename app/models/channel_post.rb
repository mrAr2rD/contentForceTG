# frozen_string_literal: true

class ChannelPost < ApplicationRecord
  # Таблица транслитерации кириллицы
  TRANSLIT_MAP = {
    "а" => "a", "б" => "b", "в" => "v", "г" => "g", "д" => "d", "е" => "e", "ё" => "yo",
    "ж" => "zh", "з" => "z", "и" => "i", "й" => "y", "к" => "k", "л" => "l", "м" => "m",
    "н" => "n", "о" => "o", "п" => "p", "р" => "r", "с" => "s", "т" => "t", "у" => "u",
    "ф" => "f", "х" => "h", "ц" => "ts", "ч" => "ch", "ш" => "sh", "щ" => "sch", "ъ" => "",
    "ы" => "y", "ь" => "", "э" => "e", "ю" => "yu", "я" => "ya"
  }.freeze

  # Associations
  belongs_to :channel_site, counter_cache: :posts_count

  # Enums
  enum :visibility, { auto: 0, visible: 1, hidden: 2 }, default: :auto

  # Validations
  validates :telegram_message_id, presence: true, uniqueness: { scope: :channel_site_id }
  validates :telegram_date, presence: true
  validates :slug, uniqueness: { scope: :channel_site_id }, allow_blank: true,
    format: { with: /\A[a-z0-9-]+\z/, message: "допускает только строчные буквы, цифры и дефисы" }
  validates :title, length: { maximum: 200 }, allow_blank: true
  validates :excerpt, length: { maximum: 500 }, allow_blank: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && display_title.present? }
  before_validation :generate_excerpt, if: -> { excerpt.blank? && display_content.present? }

  # Scopes
  scope :published, -> { where(visibility: [ :auto, :visible ]).where.not(visibility: :hidden) }
  scope :visible, -> { where(visibility: :visible) }
  scope :hidden, -> { where(visibility: :hidden) }
  scope :featured, -> { where(featured: true) }
  scope :recent, -> { order(telegram_date: :desc) }
  scope :by_year, ->(year) { where("EXTRACT(YEAR FROM telegram_date) = ?", year) }
  scope :by_month, ->(year, month) { where("EXTRACT(YEAR FROM telegram_date) = ? AND EXTRACT(MONTH FROM telegram_date) = ?", year, month) }

  # Использовать slug вместо id в URL
  def to_param
    slug.presence || id
  end

  # Увеличить счётчик просмотров на сайте
  def increment_views!
    increment!(:site_views_count)
  end

  # Контент для отображения (custom или original)
  def display_content
    content.presence || original_text
  end

  # Заголовок для отображения
  def display_title
    title.presence || extract_title_from_text
  end

  # Excerpt для отображения
  def display_excerpt
    excerpt.presence || display_content&.truncate(300)
  end

  # Проверка наличия медиа
  def has_media?
    media.present? && media.any?
  end

  # Первое изображение из медиа
  def first_image
    return nil unless has_media?

    media.find { |m| m["type"] == "photo" }&.dig("url")
  end

  # Ссылка на оригинальный пост в Telegram
  def telegram_url
    bot = channel_site.telegram_bot
    # channel_id может быть в формате @username или -100123456789
    if bot.channel_id.present? && bot.channel_id.start_with?("@")
      username = bot.channel_id.delete("@")
      "https://t.me/#{username}/#{telegram_message_id}"
    end
  end

  # Показывать ли пост
  def should_display?
    return true if visible?
    return false if hidden?

    # auto: показываем если есть контент
    display_content.present? && display_content.length > 20
  end

  private

  def extract_title_from_text
    return nil if original_text.blank?

    # Берём первую строку или первые 100 символов
    first_line = original_text.split("\n").first&.strip
    return nil if first_line.blank?

    first_line.truncate(100)
  end

  def generate_slug
    text = display_title
    return if text.blank?

    # Транслитерация кириллицы
    transliterated = text.downcase.chars.map { |char| TRANSLIT_MAP[char] || char }.join

    # Очистка и форматирование
    base_slug = transliterated
                .gsub(/[^a-z0-9\s-]/, "")
                .gsub(/[\s_]+/, "-")
                .gsub(/-+/, "-")
                .gsub(/^-|-$/, "")
                .truncate(80, omission: "")

    # Если slug пустой, генерируем из message_id
    base_slug = "post-#{telegram_message_id}" if base_slug.blank?

    # Проверяем уникальность и добавляем суффикс если нужно
    self.slug = ensure_unique_slug(base_slug)
  end

  def ensure_unique_slug(base_slug)
    slug = base_slug
    counter = 1

    while channel_site.channel_posts.where.not(id: id).exists?(slug: slug)
      slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    slug
  end

  def generate_excerpt
    return if display_content.blank?

    # Убираем HTML теги и берём первые 300 символов
    plain_text = display_content.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip
    self.excerpt = plain_text.truncate(300)
  end
end
