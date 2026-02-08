# frozen_string_literal: true

class StyleSample < ApplicationRecord
  # Associations
  belongs_to :project

  # Constants
  SOURCE_TYPES = %w[telegram_import manual file_upload].freeze

  # Validations
  validates :content, presence: true, length: { minimum: 50, maximum: 10000 }
  validates :source_type, inclusion: { in: SOURCE_TYPES }
  validates :telegram_message_id, uniqueness: { scope: :project_id }, allow_nil: true

  # Scopes
  scope :for_analysis, -> { where(used_for_analysis: true) }
  scope :from_telegram, -> { where(source_type: "telegram_import") }
  scope :manual, -> { where(source_type: "manual") }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :set_default_source_type

  # Instance methods
  def telegram_import?
    source_type == "telegram_import"
  end

  def manual?
    source_type == "manual"
  end

  def file_upload?
    source_type == "file_upload"
  end

  def truncated_content(length = 100)
    content.truncate(length)
  end

  def word_count
    content.split(/\s+/).size
  end

  private

  def set_default_source_type
    self.source_type ||= "manual"
  end
end
