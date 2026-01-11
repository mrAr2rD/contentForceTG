class Post < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :telegram_bot, optional: true

  # Enums
  enum :status, { draft: 0, scheduled: 1, published: 2, failed: 3 }, default: :draft

  # Validations
  validates :title, presence: true, length: { minimum: 2, maximum: 200 }
  validates :content, presence: true, length: { minimum: 10, maximum: 4096 }

  # Scopes
  scope :drafts, -> { where(status: :draft) }
  scope :scheduled, -> { where(status: :scheduled) }
  scope :published, -> { where(status: :published) }
  scope :failed, -> { where(status: :failed) }
  scope :recent, -> { order(created_at: :desc) }
  scope :upcoming, -> { where(status: :scheduled).where("published_at > ?", Time.current).order(published_at: :asc) }

  # Instance methods
  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def schedule!(scheduled_time)
    update!(status: :scheduled, published_at: scheduled_time)
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
