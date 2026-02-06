# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :plan_record, class_name: 'Plan', foreign_key: 'plan_id', optional: true
  has_many :payments, dependent: :destroy

  # Enums
  enum :plan, { free: 0, starter: 1, pro: 2, business: 3 }, default: :free
  enum :status, { active: 0, canceled: 1, past_due: 2, trialing: 3 }, default: :active

  # Validations
  validates :plan, presence: true
  validates :status, presence: true

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :trialing, -> { where(status: :trialing) }

  # Callbacks
  before_create :set_defaults

  # Instance methods
  def active?
    status == 'active' || status == 'trialing'
  end

  def can_create_projects?
    return true if plan == 'business'
    return false unless active?

    current_projects_count = user.projects.count
    current_projects_count < limits['max_projects'].to_i
  end

  def can_create_posts?
    return true if plan == 'business'
    return false unless active?

    current_month_posts = user.posts.where('created_at > ?', Time.current.beginning_of_month).count
    current_month_posts < limits['max_posts_per_month'].to_i
  end

  def can_use_ai?
    return true if plan == 'business'
    return false unless active?

    current_month_ai_requests = usage['ai_requests_this_month'].to_i
    current_month_ai_requests < limits['max_ai_requests_per_month'].to_i
  end

  def increment_ai_usage!
    self.usage ||= {}
    self.usage['ai_requests_this_month'] = (usage['ai_requests_this_month'].to_i + 1)
    save!
  end

  # Универсальный метод для проверки лимитов
  def can_use?(feature, amount = 1)
    limit = limit_for(feature)
    return true if limit == Float::INFINITY || limit == -1

    usage_for(feature) + amount <= limit
  end

  # Универсальный метод для увеличения использования
  def increment_usage!(feature, amount = 1)
    self.usage ||= {}
    current_usage = usage_for(feature)
    self.usage[feature.to_s] = current_usage + amount
    save!
  end

  def limit_for(feature)
    # Сначала проверяем план из БД, затем fallback на константы
    if plan_record.present?
      plan_record.limit_for(feature)
    else
      value = PLAN_LIMITS.dig(plan.to_sym, feature)
      return Float::INFINITY if value == -1
      value || 0
    end
  end

  # Цена текущего плана
  def price
    plan_record&.price || PLAN_PRICES[plan.to_sym] || 0
  end

  # Название плана
  def plan_name
    plan_record&.name || plan.to_s.titleize
  end

  # Бесплатный ли план
  def free_plan?
    plan_record&.free? || plan.to_sym == :free
  end

  # Привязать план из БД по slug
  def assign_plan!(slug)
    self.plan_record = Plan.find_by_slug(slug)
    self.plan = slug.to_s
    save!
  end

  def usage_for(feature)
    usage&.dig(feature.to_s) || 0
  end

  def ai_generations_remaining
    limit = limit_for(:ai_generations_per_month)
    return Float::INFINITY if limit == Float::INFINITY || limit == -1

    [limit - usage_for(:ai_generations_per_month), 0].max
  end

  def reset_usage!
    self.usage = {}
    save!
  end

  # Pricing in RUB (rubles)
  PLAN_PRICES = {
    free: 0,
    starter: 590,
    pro: 1490,
    business: 2990
  }.freeze

  PLAN_LIMITS = {
    free: {
      projects: 1,
      bots: 1,
      posts_per_month: 10,
      ai_generations_per_month: 5,
      analytics: :basic
    },
    starter: {
      projects: 3,
      bots: 3,
      posts_per_month: 100,
      ai_generations_per_month: 50,
      analytics: :full
    },
    pro: {
      projects: 10,
      bots: 10,
      posts_per_month: Float::INFINITY,
      ai_generations_per_month: 500,
      ai_image_generations_per_month: 20,
      analytics: :advanced
    },
    business: {
      projects: Float::INFINITY,
      bots: Float::INFINITY,
      posts_per_month: Float::INFINITY,
      ai_generations_per_month: Float::INFINITY,
      ai_image_generations_per_month: 100,
      analytics: :premium
    }
  }.freeze

  private

  def set_defaults
    self.usage ||= {
      'ai_requests_this_month' => 0,
      'posts_this_month' => 0
    }

    self.limits ||= case plan
                    when 'free'
                      {
                        'max_projects' => 1,
                        'max_posts_per_month' => 50,
                        'max_ai_requests_per_month' => 10
                      }
                    when 'starter'
                      {
                        'max_projects' => 3,
                        'max_posts_per_month' => 300,
                        'max_ai_requests_per_month' => 100
                      }
                    when 'pro'
                      {
                        'max_projects' => 10,
                        'max_posts_per_month' => -1, # unlimited
                        'max_ai_requests_per_month' => 500
                      }
                    when 'business'
                      {
                        'max_projects' => -1, # unlimited
                        'max_posts_per_month' => -1, # unlimited
                        'max_ai_requests_per_month' => 2000
                      }
                    end

    self.current_period_start ||= Time.current
    self.current_period_end ||= 1.month.from_now
  end
end
