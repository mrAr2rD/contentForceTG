class DashboardController < ApplicationController
  before_action :authenticate_user!
  layout "dashboard"

  def index
    @user = current_user

    # Статистика
    @projects_count = current_user.projects.count
    @posts_count = current_user.posts.count
    @telegram_bots_count = current_user.projects.joins(:telegram_bots).select("telegram_bots.id").distinct.count
    @published_posts_count = current_user.posts.where(status: :published).count
    @scheduled_posts_count = current_user.posts.where(status: :scheduled).count
    @draft_posts_count = current_user.posts.where(status: :draft).count

    # AI использование за последние 30 дней
    @ai_requests_count = AiUsageLog.where(user: current_user).where("created_at > ?", 30.days.ago).count
    @ai_tokens_used = AiUsageLog.where(user: current_user).where("created_at > ?", 30.days.ago).sum(:tokens_used)

    # Подписка и план
    @subscription = current_user.subscription
    @current_plan = @subscription&.plan_record&.name || @subscription&.plan&.titleize || "Free"

    # Недавние данные
    @recent_projects = current_user.projects.order(updated_at: :desc).limit(5)
    @recent_posts = current_user.posts.includes(:project, :telegram_bot).order(created_at: :desc).limit(5)
    @scheduled_posts = current_user.posts.where(status: :scheduled).order(scheduled_at: :asc).limit(3)
  end
end
