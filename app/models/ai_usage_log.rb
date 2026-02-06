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

  # Scopes для детализированных расходов
  scope :with_costs, -> { where('cost > 0 OR input_cost > 0 OR output_cost > 0') }
  scope :free_models, -> { where(cost: 0, input_cost: [nil, 0], output_cost: [nil, 0]) }
  scope :paid_models, -> { where('cost > 0 OR input_cost > 0 OR output_cost > 0') }

  # Расчёт полной стоимости запроса
  def total_cost
    return cost if cost.to_f > 0
    (input_cost.to_f + output_cost.to_f).round(6)
  end

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
