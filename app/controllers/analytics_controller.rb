# frozen_string_literal: true

class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  layout "dashboard"

  # POST /analytics/refresh_stats
  def refresh_stats
    project = if params[:project_id].present?
                current_user.projects.find(params[:project_id])
    else
                current_user.projects.active.first
    end

    unless project
      redirect_to analytics_path, alert: "Проект не найден"
      return
    end

    # Проверяем есть ли Telegram сессия
    unless current_user.telegram_sessions.active.authorized.exists?
      redirect_to analytics_path(project_id: project.id),
                  alert: "Для обновления статистики требуется авторизация Telegram"
      return
    end

    # Запускаем обновление статистики для всех ботов проекта
    bots = project.telegram_bots.verified
    posts_count = 0

    bots.each do |bot|
      bot.posts.published.where.not(telegram_message_id: nil).find_each do |post|
        Analytics::UpdatePostViewsJob.perform_later(post.id)
        posts_count += 1
      end
    end

    redirect_to analytics_path(project_id: project.id),
                notice: "Обновление статистики запущено для #{posts_count} постов. Данные обновятся в течение нескольких минут."
  end

  def index
    @projects = current_user.projects.active
    @selected_project = if params[:project_id].present?
                          current_user.projects.find(params[:project_id])
    else
                          @projects.first
    end

    return unless @selected_project

    # Проверяем есть ли активная Telegram сессия для кнопки обновления
    @has_telegram_session = current_user.telegram_sessions.active.authorized.exists?

    # Date range for analytics (last 30 days by default)
    @date_range = params[:range] || "30"
    @start_date = @date_range.to_i.days.ago.beginning_of_day
    @end_date = Time.current.end_of_day

    # Get all bots for selected project
    @telegram_bots = @selected_project.telegram_bots.verified

    # Overall stats
    @total_posts = @selected_project.posts.published.count
    @total_views = calculate_total_views
    @total_subscribers = calculate_total_subscribers
    @average_engagement = calculate_average_engagement

    # Chart data
    @views_chart_data = prepare_views_chart_data
    @subscribers_chart_data = prepare_subscribers_chart_data
    @engagement_chart_data = prepare_engagement_chart_data
    @top_posts = get_top_posts(limit: 10)
  end

  private

  def calculate_total_views
    return 0 unless @selected_project

    PostAnalytic
      .joins(post: :project)
      .where(posts: { project_id: @selected_project.id })
      .where("post_analytics.measured_at >= ?", @start_date)
      .sum(:views)
  end

  def calculate_total_subscribers
    return 0 unless @telegram_bots.any?

    ChannelSubscriberMetric
      .where(telegram_bot_id: @telegram_bots.pluck(:id))
      .latest_for_each_bot
      .sum(:subscriber_count)
  end

  def calculate_average_engagement
    return 0.0 unless @selected_project

    analytics = PostAnalytic
                  .joins(post: :project)
                  .where(posts: { project_id: @selected_project.id })
                  .where("post_analytics.measured_at >= ?", @start_date)

    return 0.0 if analytics.empty?

    total_views = analytics.sum(:views)
    total_forwards = analytics.sum(:forwards)

    return 0.0 if total_views.zero?

    ((total_forwards.to_f / total_views) * 100).round(2)
  end

  def prepare_views_chart_data
    return [] unless @selected_project

    # Group views by day
    analytics = PostAnalytic
                  .joins(post: :project)
                  .where(posts: { project_id: @selected_project.id })
                  .where("post_analytics.measured_at >= ?", @start_date)
                  .group("DATE(post_analytics.measured_at)")
                  .select("DATE(post_analytics.measured_at) as date, SUM(views) as total_views")
                  .order("date ASC")

    analytics.map do |record|
      {
        date: record.date.strftime("%d.%m"),
        views: record.total_views
      }
    end
  end

  def prepare_subscribers_chart_data
    return [] unless @telegram_bots.any?

    # Get daily snapshots for all bots
    metrics = ChannelSubscriberMetric
                .where(telegram_bot_id: @telegram_bots.pluck(:id))
                .where("measured_at >= ?", @start_date)
                .group("DATE(measured_at)", :telegram_bot_id)
                .select("DATE(measured_at) as date, telegram_bot_id, MAX(subscriber_count) as count")
                .order("date ASC")

    # Group by date and sum all bots
    metrics.group_by(&:date).map do |date, records|
      {
        date: date.strftime("%d.%m"),
        subscribers: records.sum(&:count)
      }
    end
  end

  def prepare_engagement_chart_data
    return [] unless @selected_project

    analytics = PostAnalytic
                  .joins(post: :project)
                  .where(posts: { project_id: @selected_project.id })
                  .where("post_analytics.measured_at >= ?", @start_date)
                  .group("DATE(post_analytics.measured_at)")
                  .select("DATE(post_analytics.measured_at) as date, SUM(forwards) as forwards, SUM(views) as views")
                  .order("date ASC")

    analytics.map do |record|
      rate = record.views.zero? ? 0.0 : ((record.forwards.to_f / record.views) * 100).round(2)
      {
        date: record.date.strftime("%d.%m"),
        rate: rate
      }
    end
  end

  def get_top_posts(limit: 10)
    return Post.none unless @selected_project

    # Get posts with their latest analytics
    # Using includes to prevent N+1 when accessing associations in views
    @selected_project.posts
                     .published
                     .includes(:telegram_bot)
                     .joins(:post_analytics)
                     .select("posts.*, MAX(post_analytics.views) as max_views, MAX(post_analytics.forwards) as max_forwards")
                     .group("posts.id")
                     .order("max_views DESC")
                     .limit(limit)
  end
end
