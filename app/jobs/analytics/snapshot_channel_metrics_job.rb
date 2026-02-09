# frozen_string_literal: true

module Analytics
  class SnapshotChannelMetricsJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: 5.seconds, attempts: 3

    def perform(telegram_bot_id)
      bot = TelegramBot.find(telegram_bot_id)
      return unless bot.verified?

      begin
        # Пробуем получить данные через Pyrogram (MTProto API)
        current_stats = fetch_via_pyrogram(bot)

        # Если Pyrogram недоступен — fallback на Bot API
        current_stats ||= fetch_via_bot_api(bot)

        return unless current_stats && current_stats[:subscriber_count]

        current_count = current_stats[:subscriber_count]

        # Get previous metric to calculate growth
        previous_metric = bot.channel_subscriber_metrics.recent.first
        previous_count = previous_metric&.subscriber_count || current_count

        # Calculate growth
        growth = current_count - previous_count

        # Create snapshot
        bot.channel_subscriber_metrics.create!(
          subscriber_count: current_count,
          subscriber_growth: growth,
          churn_rate: calculate_churn_rate(previous_metric, growth),
          measured_at: Time.current
        )

        Rails.logger.info("Snapshot created for bot #{bot.id}: #{current_count} subscribers (#{growth >= 0 ? '+' : ''}#{growth})")

        # Update bot's channel_name if we got new data
        if current_stats[:title].present? && current_stats[:title] != bot.channel_name
          bot.update(channel_name: current_stats[:title])
        end
      rescue StandardError => e
        Rails.logger.error("Failed to snapshot channel metrics for bot #{bot.id}: #{e.message}")
        raise
      end
    end

    private

    def fetch_via_pyrogram(bot)
      channel_info = Telegram::ChannelInfoService.new(bot).fetch
      return nil unless channel_info

      {
        subscriber_count: channel_info[:members_count] || channel_info["members_count"] || 0,
        title: channel_info[:title] || channel_info["title"]
      }
    rescue StandardError => e
      Rails.logger.warn("Pyrogram fetch failed for bot #{bot.id}: #{e.message}")
      nil
    end

    def fetch_via_bot_api(bot)
      analytics_service = Telegram::AnalyticsService.new(bot)
      current_stats = analytics_service.fetch_channel_statistics
      {
        subscriber_count: current_stats[:subscriber_count] || 0,
        title: current_stats[:title]
      }
    rescue StandardError => e
      Rails.logger.warn("Bot API fetch failed for bot #{bot.id}: #{e.message}")
      nil
    end

    def calculate_churn_rate(previous_metric, growth)
      return 0.0 unless previous_metric

      # Если был отток (отрицательный рост), считаем churn rate
      if growth.negative? && previous_metric.subscriber_count.positive?
        ((growth.abs.to_f / previous_metric.subscriber_count) * 100).round(2)
      else
        0.0
      end
    end
  end
end
