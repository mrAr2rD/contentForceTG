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
      # Группируем посты по ботам для batch-запросов
      posts_by_bot = Post.published
                         .where.not(telegram_message_id: nil)
                         .where("published_at > ?", 7.days.ago)
                         .includes(:telegram_bot)
                         .group_by(&:telegram_bot)

      posts_by_bot.each do |bot, posts|
        next unless bot&.verified?

        update_batch_for_bot(bot, posts)
      rescue StandardError => e
        Rails.logger.error("Failed to update analytics batch for bot #{bot&.id}: #{e.message}")
      end
    end

    def update_batch_for_bot(bot, posts)
      # Пробуем получить реальные данные через Pyrogram
      stats_service = Telegram::PostStatsService.new(bot)
      stats = stats_service.fetch_batch(posts)

      if stats.present?
        # Есть реальные данные — обновляем
        save_stats_batch(posts, stats)
        Rails.logger.info("Updated analytics for #{stats.size} posts via Pyrogram")
      else
        # Нет сессии или ошибка — fallback на webhook данные
        Rails.logger.info("No Pyrogram session available, using webhook data only")
      end
    end

    def save_stats_batch(posts, stats)
      stats_by_id = stats.index_by { |s| s[:message_id] || s["message_id"] }

      posts.each do |post|
        stat = stats_by_id[post.telegram_message_id]
        next unless stat
        next if stat[:not_found] || stat["not_found"]

        save_post_analytics(post, {
          views: stat[:views] || stat["views"] || 0,
          forwards: stat[:forwards] || stat["forwards"] || 0,
          reactions: stat[:reactions] || stat["reactions"] || {}
        })
      end
    end

    def update_single_post(post_id)
      post = Post.find_by(id: post_id)
      return unless post&.published? && post.telegram_message_id.present?

      bot = post.telegram_bot
      return unless bot&.verified?

      # Пробуем получить реальные данные через Pyrogram
      stats_service = Telegram::PostStatsService.new(bot)
      stat = stats_service.fetch_single(post)

      if stat.present? && !stat[:not_found]
        save_post_analytics(post, {
          views: stat[:views] || stat["views"] || 0,
          forwards: stat[:forwards] || stat["forwards"] || 0,
          reactions: stat[:reactions] || stat["reactions"] || {}
        })
        Rails.logger.info("Updated analytics for post #{post.id} via Pyrogram: #{stat[:views]} views")
      else
        # Fallback — используем данные из AnalyticsService (webhook данные)
        stats = Telegram::AnalyticsService.new(bot).fetch_post_statistics(post)
        save_post_analytics(post, stats)
        Rails.logger.info("Updated analytics for post #{post.id} from webhook data: #{stats[:views]} views")
      end
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("Post #{post_id} not found for analytics update")
    rescue StandardError => e
      Rails.logger.error("Failed to update post analytics for #{post_id}: #{e.message}")
      raise
    end

    def save_post_analytics(post, stats)
      post.with_lock do
        last_analytics = post.post_analytics.recent.first

        # Если последняя запись была создана менее 5 минут назад — обновляем её
        if last_analytics && last_analytics.measured_at > 5.minutes.ago
          last_analytics.update!(
            views: stats[:views] || last_analytics.views,
            forwards: stats[:forwards] || last_analytics.forwards,
            reactions: stats[:reactions] || last_analytics.reactions || {},
            measured_at: Time.current
          )
        else
          # Создаём новую запись
          post.post_analytics.create!(
            telegram_message_id: post.telegram_message_id,
            views: stats[:views] || 0,
            forwards: stats[:forwards] || 0,
            reactions: stats[:reactions] || {},
            button_clicks: {},
            measured_at: Time.current
          )
        end
      end
    end
  end
end
