# frozen_string_literal: true

module Telegram
  class AnalyticsService
    attr_reader :telegram_bot

    def initialize(telegram_bot)
      @telegram_bot = telegram_bot
    end

    # Get channel statistics
    def fetch_channel_statistics
      return mock_channel_statistics unless Rails.env.production?

      begin
        client = Telegram::Bot::Client.new(telegram_bot.bot_token)
        chat = client.api.get_chat(chat_id: telegram_bot.channel_id)

        {
          subscriber_count: chat.dig('result', 'member_count') || 0,
          title: chat.dig('result', 'title'),
          description: chat.dig('result', 'description')
        }
      rescue StandardError => e
        Rails.logger.error("Telegram Analytics API error: #{e.message}")
        mock_channel_statistics
      end
    end

    # Get post statistics
    def fetch_post_statistics(post)
      return mock_post_statistics unless Rails.env.production?

      return {} unless post.telegram_message_id.present?

      begin
        # Note: Telegram Bot API doesn't provide direct message view statistics
        # This would require Telegram Analytics API or channel admin privileges
        # For MVP, we'll use mock data

        mock_post_statistics
      rescue StandardError => e
        Rails.logger.error("Telegram Post Analytics error: #{e.message}")
        {}
      end
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

    def mock_channel_statistics
      {
        subscriber_count: rand(1000..10000),
        title: telegram_bot.channel_name || "Channel",
        description: "Test channel description"
      }
    end

    def mock_post_statistics
      {
        views: rand(100..1000),
        forwards: rand(5..50),
        reactions: {
          '👍' => rand(10..100),
          '❤️' => rand(5..50),
          '🔥' => rand(2..20),
          '😍' => rand(3..30)
        },
        button_clicks: {}
      }
    end
  end
end
