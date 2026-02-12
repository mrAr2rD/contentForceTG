# frozen_string_literal: true

module Admin
  class DashboardController < Admin::ApplicationController
    def index
      @users_count = User.count
      @projects_count = Project.count
      @posts_count = Post.count
      @telegram_bots_count = TelegramBot.count
      @subscriptions_count = Subscription.count

      @recent_users = User.order(created_at: :desc).limit(5)
      @recent_posts = Post.order(created_at: :desc).limit(5)

      # ROI данные за последние 30 дней
      load_roi_data

      # Статистика постов
      load_post_analytics

      # Статистика каналов
      load_channel_metrics

      # AI использование
      load_ai_usage_stats
    end

    private

    def load_roi_data
      @roi_calculator = Analytics::RoiCalculatorService.new(period: 30.days)
      @roi_summary = @roi_calculator.calculate
    rescue StandardError => e
      Rails.logger.error("Failed to calculate ROI: #{e.message}")
      @roi_summary = nil
      @roi_error = "Не удалось загрузить ROI данные. Возможно, требуется выполнить миграции."
    end

    def load_post_analytics
      return unless PostAnalytic.table_exists?

      @post_analytics = {
        total_views: PostAnalytic.total_views,
        total_forwards: PostAnalytic.total_forwards,
        average_views: PostAnalytic.average_views.round(1),
        published_posts: Post.published.count
      }
    rescue StandardError => e
      Rails.logger.error("Failed to load post analytics: #{e.message}")
      @post_analytics = nil
    end

    def load_channel_metrics
      return unless ChannelSubscriberMetric.table_exists?

      @channel_metrics = {
        total_subscribers: ChannelSubscriberMetric.latest_for_each_bot.sum(:subscriber_count),
        total_growth: ChannelSubscriberMetric.where("measured_at > ?", 30.days.ago).sum(:subscriber_growth),
        average_churn: ChannelSubscriberMetric.where("measured_at > ?", 30.days.ago).average(:churn_rate)&.round(2) || 0,
        active_bots: TelegramBot.verified.count
      }
    rescue StandardError => e
      Rails.logger.error("Failed to load channel metrics: #{e.message}")
      @channel_metrics = nil
    end

    def load_ai_usage_stats
      return unless AiUsageLog.table_exists?

      @ai_usage = {
        total_requests: AiUsageLog.count,
        requests_today: AiUsageLog.where("created_at > ?", 1.day.ago).count,
        total_tokens: AiUsageLog.sum(:tokens_used),
        total_cost: AiUsageLog.sum(:cost)
      }
    rescue StandardError => e
      Rails.logger.error("Failed to load AI usage stats: #{e.message}")
      @ai_usage = nil
    end
  end
end
