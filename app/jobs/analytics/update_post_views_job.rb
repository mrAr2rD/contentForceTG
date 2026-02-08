# frozen_string_literal: true

module Analytics
  class UpdatePostViewsJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: 5.seconds, attempts: 3

    # Может вызываться двумя способами:
    # 1. Без аргументов (из recurring) - обновляет все опубликованные посты за последние 7 дней
    # 2. С post_id - обновляет конкретный пост
    def perform(post_id = nil)
      if post_id.nil?
        update_all_recent_posts
      else
        update_single_post(post_id)
      end
    end

    private

    def update_all_recent_posts
      # Находим посты опубликованные за последние 7 дней с telegram_message_id
      posts = Post.published
                  .where.not(telegram_message_id: nil)
                  .where("published_at > ?", 7.days.ago)
                  .includes(:telegram_bot)

      posts.find_each do |post|
        update_single_post(post.id)
      rescue StandardError => e
        Rails.logger.error("Failed to update analytics for post #{post.id}: #{e.message}")
        # Продолжаем с остальными постами
      end
    end

    def update_single_post(post_id)
      post = Post.find_by(id: post_id)
      return unless post&.published? && post.telegram_message_id.present?

      bot = post.telegram_bot
      return unless bot&.verified?

      stats = fetch_post_statistics(bot, post)

      post.post_analytics.create!(
        telegram_message_id: post.telegram_message_id,
        views: stats[:views] || 0,
        forwards: stats[:forwards] || 0,
        reactions: stats[:reactions] || {},
        button_clicks: stats[:button_clicks] || {},
        measured_at: Time.current
      )

      Rails.logger.info("Updated analytics for post #{post.id}: #{stats[:views]} views")
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("Post #{post_id} not found for analytics update")
    rescue StandardError => e
      Rails.logger.error("Failed to update post analytics for #{post_id}: #{e.message}")
      raise
    end

    def fetch_post_statistics(bot, post)
      Telegram::AnalyticsService.new(bot).fetch_post_statistics(post)
    end
  end
end
