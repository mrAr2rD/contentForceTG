# frozen_string_literal: true

class AiUsageLog < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true

  enum :purpose, {
    content_generation: 0,
    content_improvement: 1,
    image_generation: 2,
    hashtag_generation: 3
  }

  validates :model_used, presence: true
  validates :tokens_used, numericality: { greater_than_or_equal_to: 0 }
  validates :cost, numericality: { greater_than_or_equal_to: 0 }

  # Статистика использования
  def self.total_cost_for_user(user, period = 30.days)
    where(user: user)
      .where('created_at > ?', period.ago)
      .sum(:cost)
  end

  def self.popular_models(limit = 5)
    group(:model_used)
      .order('count_all DESC')
      .limit(limit)
      .count
  end

  def self.usage_by_purpose
    group(:purpose).count
  end

  def self.daily_usage(days = 30)
    where('created_at > ?', days.days.ago)
      .group_by_day(:created_at)
      .sum(:tokens_used)
  end
end
