# frozen_string_literal: true

module Telegram
  class AnalyticsService
    attr_reader :telegram_bot

    def initialize(telegram_bot)
      @telegram_bot = telegram_bot
    end

    # Get channel statistics
    def fetch_channel_statistics
      begin
        api = Telegram::Bot::Api.new(telegram_bot.bot_token)
        chat = api.get_chat(chat_id: telegram_bot.channel_id)

        {
          subscriber_count: chat.member_count || 0,
          title: chat.title || telegram_bot.channel_name,
          description: chat.description,
          username: chat.username
        }
      rescue Telegram::Bot::Exceptions::ResponseError => e
        Rails.logger.error("Telegram API error for bot #{telegram_bot.id}: #{e.message}")
        # Return last known data or mock
        last_metric = telegram_bot.channel_subscriber_metrics.recent.first
        if last_metric
          {
            subscriber_count: last_metric.subscriber_count,
            title: telegram_bot.channel_name,
            description: nil
          }
        else
          fallback_channel_statistics
        end
      rescue StandardError => e
        Rails.logger.error("Telegram Analytics API error: #{e.message}")
        fallback_channel_statistics
      end
    end

    # Get post statistics
    # Пробует получить реальные данные через Pyrogram, fallback на webhook данные
    def fetch_post_statistics(post)
      return {} unless post.telegram_message_id.present?

      # Пробуем получить реальные данные через Pyrogram
      stats = fetch_via_pyrogram(post)
      return stats if stats.present?

      # Fallback: возвращаем последние известные данные из БД
      fetch_from_database(post)
    end

    # Schedule analytics updates for all published posts
    def schedule_post_analytics_updates
      telegram_bot.posts.published.find_each do |post|
        Analytics::UpdatePostViewsJob.perform_later(post.id)
      end
    end

    # Schedule channel metrics snapshot
    def schedule_channel_snapshot
      Analytics::SnapshotChannelMetricsJob.perform_later(telegram_bot.id)
    end

    private

    # Получить статистику через Pyrogram (MTProto API)
    def fetch_via_pyrogram(post)
      stats_service = PostStatsService.new(telegram_bot)
      stat = stats_service.fetch_single(post)

      return nil unless stat.present? && !stat[:not_found]

      {
        views: stat[:views] || stat["views"] || 0,
        forwards: stat[:forwards] || stat["forwards"] || 0,
        reactions: stat[:reactions] || stat["reactions"] || {},
        button_clicks: {}
      }
    rescue StandardError => e
      Rails.logger.error("Pyrogram stats error for post #{post.id}: #{e.message}")
      nil
    end

    # Получить последние данные из БД (webhook данные)
    def fetch_from_database(post)
      last_analytics = post.post_analytics.recent.first

      if last_analytics
        {
          views: last_analytics.views,
          forwards: last_analytics.forwards,
          reactions: last_analytics.reactions || {},
          button_clicks: last_analytics.button_clicks || {}
        }
      else
        # Для новых постов возвращаем нулевые значения
        {
          views: 0,
          forwards: 0,
          reactions: {},
          button_clicks: {}
        }
      end
    end

    def fallback_channel_statistics
      # Возвращаем последние известные данные
      last_metric = telegram_bot.channel_subscriber_metrics.recent.first
      {
        subscriber_count: last_metric&.subscriber_count || 0,
        title: telegram_bot.channel_name || "Channel",
        description: nil
      }
    end

    # Parse Telegram reactions format to our format
    def parse_reactions(reactions_data)
      return {} unless reactions_data.is_a?(Array)

      result = {}
      reactions_data.each do |reaction|
        emoji = reaction.dig("type", "emoji")
        count = reaction["total_count"] || 0
        result[emoji] = count if emoji.present?
      end
      result
    end
  end
end
