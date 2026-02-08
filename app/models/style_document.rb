# frozen_string_literal: true

class StyleDocument < ApplicationRecord
  # Associations
  belongs_to :project

  # Constants
  ALLOWED_CONTENT_TYPES = %w[text/plain text/markdown text/x-markdown application/octet-stream].freeze
  MAX_FILE_SIZE = 1.megabyte

  # Validations
  validates :filename, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  validates :file_size, numericality: { less_than_or_equal_to: MAX_FILE_SIZE }, allow_nil: true

  # Scopes
  scope :for_analysis, -> { where(used_for_analysis: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def extension
    File.extname(filename).downcase
  end

  def markdown?
    extension.in?(%w[.md .markdown])
  end

  def text?
    extension.in?(%w[.txt .text])
  end

  def truncated_content(length = 100)
    content.truncate(length)
  end

  def word_count
    content.split(/\s+/).size
  end

  def formatted_file_size
    return nil unless file_size

    if file_size < 1024
      "#{file_size} B"
    elsif file_size < 1024 * 1024
      "#{(file_size / 1024.0).round(1)} KB"
    else
      "#{(file_size / (1024.0 * 1024)).round(1)} MB"
    end
  end
end
