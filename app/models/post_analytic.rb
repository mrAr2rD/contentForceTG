class PostAnalytic < ApplicationRecord
  # Associations
  belongs_to :post

  # Validations
  validates :measured_at, presence: true
  validates :views, :forwards, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :recent, -> { order(measured_at: :desc) }
  scope :for_post, ->(post_id) { where(post_id: post_id) }
  scope :between, ->(start_date, end_date) { where(measured_at: start_date..end_date) }
  scope :latest_for_each_post, -> {
    where(id: select("DISTINCT ON (post_id) id").order(:post_id, measured_at: :desc))
  }

  # Class methods
  def self.total_views
    sum(:views)
  end

  def self.total_forwards
    sum(:forwards)
  end

  def self.average_views
    average(:views)&.to_f || 0.0
  end

  # Instance methods
  def engagement_rate
    return 0.0 if views.zero?
    ((forwards.to_f / views) * 100).round(2)
  end

  def total_reactions
    reactions.values.sum
  end

  def reaction_rate
    return 0.0 if views.zero?
    ((total_reactions.to_f / views) * 100).round(2)
  end
end
