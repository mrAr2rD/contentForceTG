# frozen_string_literal: true

module Analytics
  class SnapshotChannelMetricsJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :exponentially_longer, attempts: 3

    def perform(telegram_bot_id)
      bot = TelegramBot.find(telegram_bot_id)
      return unless bot.verified?

      begin
        # Get current subscriber count from Telegram API
        current_stats = fetch_channel_statistics(bot)
        current_count = current_stats[:subscriber_count]

        # Get previous metric to calculate growth
        previous_metric = bot.channel_subscriber_metrics.recent.first
        previous_count = previous_metric&.subscriber_count || 0

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
      rescue StandardError => e
        Rails.logger.error("Failed to snapshot channel metrics for bot #{bot.id}: #{e.message}")
        raise
      end
    end

    private

    def fetch_channel_statistics(bot)
      # This would call Telegram Bot API to get channel statistics
      # For now, return mock data (implement real API call later)

      # Real implementation would use:
      # client = Telegram::Bot::Client.new(bot.bot_token)
      # chat = client.api.get_chat(chat_id: bot.channel_id)
      # member_count = chat.dig('result', 'member_count')

      {
        subscriber_count: rand(1000..10000)
      }
    end
  end
end
