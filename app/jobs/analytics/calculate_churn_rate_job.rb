# frozen_string_literal: true

module Analytics
  class CalculateChurnRateJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: 5.seconds, attempts: 3

    def perform(telegram_bot_id)
      bot = TelegramBot.find(telegram_bot_id)
      return unless bot.verified?

      begin
        # Get metrics from last 30 days
        thirty_days_ago = 30.days.ago
        metrics = bot.channel_subscriber_metrics
                     .where("measured_at >= ?", thirty_days_ago)
                     .order(measured_at: :asc)

        return if metrics.count < 2

        # Calculate churn rate based on subscriber losses
        start_count = metrics.first.subscriber_count
        end_count = metrics.last.subscriber_count
        negative_growth = metrics.where("subscriber_growth < 0").sum(:subscriber_growth).abs

        # Churn rate = (lost subscribers / average subscribers) * 100
        average_subscribers = (start_count + end_count) / 2.0
        churn_rate = if average_subscribers > 0
                       (negative_growth / average_subscribers * 100).round(2)
        else
                       0.0
        end

        # Update latest metric with calculated churn rate
        latest_metric = metrics.last
        latest_metric.update!(churn_rate: churn_rate)

        Rails.logger.info("Calculated churn rate for bot #{bot.id}: #{churn_rate}%")
      rescue StandardError => e
        Rails.logger.error("Failed to calculate churn rate for bot #{bot.id}: #{e.message}")
        raise
      end
    end
  end
end
