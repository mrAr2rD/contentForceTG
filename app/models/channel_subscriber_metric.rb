class ChannelSubscriberMetric < ApplicationRecord
  # Associations
  belongs_to :telegram_bot

  # Validations
  validates :measured_at, presence: true
  validates :subscriber_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :churn_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  # Scopes
  scope :recent, -> { order(measured_at: :desc) }
  scope :for_bot, ->(bot_id) { where(telegram_bot_id: bot_id) }
  scope :between, ->(start_date, end_date) { where(measured_at: start_date..end_date) }
  scope :daily, -> { where("DATE(measured_at) = DATE(measured_at)").group("DATE(measured_at)") }
  scope :latest_for_each_bot, -> {
    where(id: select('DISTINCT ON (telegram_bot_id) id').order(:telegram_bot_id, measured_at: :desc))
  }

  # Class methods
  def self.average_subscribers
    average(:subscriber_count)&.to_f || 0.0
  end

  def self.total_growth
    sum(:subscriber_growth)
  end

  def self.average_churn
    average(:churn_rate)&.to_f || 0.0
  end

  # Instance methods
  def growth_rate
    return 0.0 if subscriber_count.zero?
    ((subscriber_growth.to_f / subscriber_count) * 100).round(2)
  end

  def net_growth
    subscriber_growth - (subscriber_count * (churn_rate / 100)).round
  end
end
