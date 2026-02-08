# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :plan_record, class_name: "Plan", foreign_key: "plan_id", optional: true
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
  before_create :assign_plan_record

  # Instance methods
  def active?
    status == "active" || status == "trialing"
  end

  def can_create_projects?
    return true if plan == "business"
    return false unless active?

    current_projects_count = user.projects.count
    current_projects_count < limits["max_projects"].to_i
  end

  def can_create_posts?
    return true if plan == "business"
    return false unless active?

    current_month_posts = user.posts.where("created_at > ?", Time.current.beginning_of_month).count
    current_month_posts < limits["max_posts_per_month"].to_i
  end

  def can_use_ai?
    return true if plan == "business"
    return false unless active?

    current_month_ai_requests = usage["ai_requests_this_month"].to_i
    current_month_ai_requests < limits["max_ai_requests_per_month"].to_i
  end

  def increment_ai_usage!
    self.usage ||= {}
    self.usage["ai_requests_this_month"] = (usage["ai_requests_this_month"].to_i + 1)
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

  # Получение лимита для фичи
  # Приоритет: plan_record → Plan.cached_find_by_slug → PLAN_LIMITS (fallback)
  def limit_for(feature)
    if plan_record.present?
      plan_record.limit_for(feature)
    elsif (cached_plan = Plan.cached_find_by_slug(plan))
      cached_plan.limit_for(feature)
    else
      # Fallback на константы (deprecated)
      value = PLAN_LIMITS.dig(plan.to_sym, feature)
      return Float::INFINITY if value == -1
      value || 0
    end
  end

  # Цена текущего плана
  # Приоритет: plan_record → Plan.cached_find_by_slug → PLAN_PRICES (fallback)
  def price
    if plan_record.present?
      plan_record.price
    elsif (cached_plan = Plan.cached_find_by_slug(plan))
      cached_plan.price
    else
      # Fallback на константы (deprecated)
      PLAN_PRICES[plan.to_sym] || 0
    end
  end

  # Название плана
  def plan_name
    if plan_record.present?
      plan_record.name
    elsif (cached_plan = Plan.cached_find_by_slug(plan))
      cached_plan.name
    else
      plan.to_s.titleize
    end
  end

  # Бесплатный ли план
  def free_plan?
    plan_record&.free? || Plan.cached_find_by_slug(plan)&.free? || plan.to_sym == :free
  end

  # Привязать план из БД по slug
  def assign_plan!(slug)
    self.plan_record = Plan.cached_find_by_slug(slug) || Plan.find_by_slug(slug)
    self.plan = slug.to_s
    save!
  end

  def usage_for(feature)
    usage&.dig(feature.to_s) || 0
  end

  def ai_generations_remaining
    limit = limit_for(:ai_generations_per_month)
    return Float::INFINITY if limit == Float::INFINITY || limit == -1

    [ limit - usage_for(:ai_generations_per_month), 0 ].max
  end

  def reset_usage!
    self.usage = {}
    save!
  end

  # =============================================================================
  # DEPRECATED: Константы оставлены для обратной совместимости
  # Используйте Plan.cached_all и Plan.cached_find_by_slug вместо них
  # =============================================================================

  # @deprecated Используйте Plan.cached_find_by_slug(slug).price
  PLAN_PRICES = {
    free: 0,
    starter: 590,
    pro: 1490,
    business: 2990
  }.freeze

  # @deprecated Используйте Plan.cached_find_by_slug(slug).limit_for(feature)
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

  # Автоматически привязывает plan_record при создании
  def assign_plan_record
    return if plan_record.present?

    self.plan_record = Plan.cached_find_by_slug(plan) || Plan.find_by_slug(plan)
  end

  def set_defaults
    self.usage ||= {
      "ai_requests_this_month" => 0,
      "posts_this_month" => 0
    }

    # Копируем лимиты из плана (для фиксации на момент подписки)
    self.limits ||= build_limits_from_plan

    self.current_period_start ||= Time.current
    self.current_period_end ||= 1.month.from_now
  end

  # Получает лимиты из Plan или fallback на хардкод
  def build_limits_from_plan
    source_plan = Plan.cached_find_by_slug(plan) || Plan.find_by_slug(plan)

    if source_plan.present?
      {
        "max_projects" => source_plan.limit_for(:projects),
        "max_posts_per_month" => source_plan.limit_for(:posts_per_month),
        "max_ai_requests_per_month" => source_plan.limit_for(:ai_generations_per_month)
      }.transform_values { |v| v == Float::INFINITY ? -1 : v }
    else
      # Fallback для случаев когда Plan ещё не существует в БД
      case plan
      when "free"
        { "max_projects" => 1, "max_posts_per_month" => 50, "max_ai_requests_per_month" => 10 }
      when "starter"
        { "max_projects" => 3, "max_posts_per_month" => 300, "max_ai_requests_per_month" => 100 }
      when "pro"
        { "max_projects" => 10, "max_posts_per_month" => -1, "max_ai_requests_per_month" => 500 }
      when "business"
        { "max_projects" => -1, "max_posts_per_month" => -1, "max_ai_requests_per_month" => 2000 }
      end
    end
  end
end
