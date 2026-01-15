class Post < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :telegram_bot, optional: true
  has_one_attached :image

  # Enums
  enum :status, { draft: 0, scheduled: 1, published: 2, failed: 3 }, default: :draft

  # Validations
  validates :title, presence: true, length: { minimum: 2, maximum: 200 }
  validates :content, presence: true, length: { minimum: 10, maximum: 4096 }

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
