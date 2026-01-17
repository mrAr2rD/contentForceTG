# frozen_string_literal: true

module Analytics
  class SnapshotChannelMetricsJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :exponentially_longer, attempts: 3

    def perform(telegram_bot_id)
      bot = TelegramBot.find(telegram_bot_id)
      return unless bot.verified?

      begin
        # Get current subscriber count from Telegram API using analytics service
        analytics_service = Telegram::AnalyticsService.new(bot)
        current_stats = analytics_service.fetch_channel_statistics
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
          churn_rate: 0.0, # Will be calculated by CalculateChurnRateJob
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
  end
end
