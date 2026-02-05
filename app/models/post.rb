class Post < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :telegram_bot, optional: true
  has_one_attached :image
  has_many :post_analytics, dependent: :destroy

  # Callbacks for manual purge (bypass Solid Queue until tables exist)
  before_destroy :purge_image_attachment

  # Enums
  enum :status, { draft: 0, scheduled: 1, published: 2, failed: 3 }, default: :draft
  enum :post_type, { text: 0, image: 1, image_button: 2 }, default: :text

  # Validations
  validates :title, length: { minimum: 2, maximum: 200 }, allow_blank: true
  validates :content, presence: true, length: { minimum: 10, maximum: 4096 }, unless: :draft?
  validates :content, length: { maximum: 4096 }, if: :draft?, allow_blank: true
  validates :button_text, presence: true, length: { maximum: 64 }, if: :image_button?
  validates :button_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, if: :image_button?
  validate :telegram_caption_length, unless: :draft?
  validate :image_required_for_image_posts, unless: :draft?

  # Callbacks
  after_create :schedule_publication, if: -> { scheduled? && published_at.present? }

  # Scopes
  scope :drafts, -> { where(status: :draft) }
  scope :scheduled, -> { where(status: :scheduled) }
  scope :published, -> { where(status: :published) }
  scope :failed, -> { where(status: :failed) }
  scope :recent, -> { order(created_at: :desc) }
  scope :upcoming, -> { where(status: :scheduled).where("published_at > ?", Time.current).order(published_at: :asc) }

  # Instance methods
  def publish!
    result = Telegram::PublishService.new(self).publish!
    update!(
      status: :published,
      published_at: Time.current,
      telegram_message_id: result.message_id
    )

    # Schedule periodic analytics updates for this post
    schedule_analytics_updates

    result
  rescue StandardError => e
    mark_as_failed!(e.message)
    raise
  end

  def schedule!(scheduled_time)
    update!(status: :scheduled, published_at: scheduled_time)
    schedule_publication! if persisted?
  end

  def schedule_publication!
    return unless scheduled? && published_at.present?
    PublishPostJob.set(wait_until: published_at).perform_later(id)
  end

  def schedule_publication
    schedule_publication! if scheduled? && published_at.present?
  end

  def mark_as_failed!(error_message = nil)
    update!(status: :failed, error_details: error_message)
  end

  def reset_to_draft!
    update!(status: :draft, published_at: nil, telegram_message_id: nil)
  end

  def published?
    status == "published"
  end

  def scheduled?
    status == "scheduled"
  end

  def draft?
    status == "draft"
  end

  def failed?
    status == "failed"
  end

  private

  def purge_image_attachment
    image.purge if image.attached?
  end

  def telegram_caption_length
    return unless content.present?
    return if text? # Text posts can be up to 4096 characters

    # Image and image_button posts have a 1024 character limit for captions
    if (image? || image_button?) && content.length > 1024
      errors.add(:content, "слишком длинный для Telegram (максимум 1024 символа для постов с картинкой, сейчас #{content.length})")
    end
  end

  def image_required_for_image_posts
    return if text?
    return if image.attached?

    errors.add(:image, "обязательно для постов с изображением")
  end

  def schedule_analytics_updates
    return unless published? && telegram_message_id.present? && telegram_bot.present?

    # First update: 1 hour after publication
    Analytics::UpdatePostViewsJob.set(wait: 1.hour).perform_later(id)

    # Second update: 6 hours after publication
    Analytics::UpdatePostViewsJob.set(wait: 6.hours).perform_later(id)

    # Third update: 24 hours after publication
    Analytics::UpdatePostViewsJob.set(wait: 24.hours).perform_later(id)

    # Fourth update: 7 days after publication (for long-term stats)
    Analytics::UpdatePostViewsJob.set(wait: 7.days).perform_later(id)
  rescue StandardError => e
    Rails.logger.error("Failed to schedule analytics updates for post #{id}: #{e.message}")
    # Don't fail publish if scheduling fails
  end
end
