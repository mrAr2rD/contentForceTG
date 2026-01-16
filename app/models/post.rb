class Post < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :telegram_bot, optional: true
  has_one_attached :image
  has_many :post_analytics, dependent: :destroy

  # Enums
  enum :status, { draft: 0, scheduled: 1, published: 2, failed: 3 }, default: :draft
  enum :post_type, { text: 0, image: 1, image_button: 2 }, default: :text

  # Validations
  validates :title, length: { minimum: 2, maximum: 200 }, allow_blank: true
  validates :content, presence: true, length: { minimum: 10, maximum: 4096 }, unless: :draft?
  validates :content, length: { maximum: 4096 }, if: :draft?, allow_blank: true
  validates :button_text, presence: true, length: { maximum: 64 }, if: :image_button?
  validates :button_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, if: :image_button?

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
    update!(status: :failed)
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
end
