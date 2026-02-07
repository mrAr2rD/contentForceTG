# frozen_string_literal: true

module Analytics
  class UpdatePostViewsJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: 5.seconds, attempts: 3

    def perform(post_id)
      post = Post.find(post_id)
      return unless post.published? && post.telegram_message_id.present?

      # Get analytics from Telegram API via bot
      bot = post.telegram_bot
      return unless bot&.verified?

      begin
        stats = fetch_post_statistics(bot, post)

        # Create analytics record
        post.post_analytics.create!(
          telegram_message_id: post.telegram_message_id,
          views: stats[:views] || 0,
          forwards: stats[:forwards] || 0,
          reactions: stats[:reactions] || {},
          button_clicks: stats[:button_clicks] || {},
          measured_at: Time.current
        )

        Rails.logger.info("Updated analytics for post #{post.id}: #{stats[:views]} views")
      rescue StandardError => e
        Rails.logger.error("Failed to update post analytics for #{post.id}: #{e.message}")
        raise
      end
    end

    private

    def fetch_post_statistics(bot, post)
      Telegram::AnalyticsService.new(bot).fetch_post_statistics(post)
    end

    def old_fetch_post_statistics(bot, post)
      # This would call Telegram Bot API to get message statistics
      # For now, return mock data (implement real API call later)

      # Real implementation would use:
      # client = Telegram::Bot::Client.new(bot.bot_token)
      # message = client.api.get_message_statistics(chat_id: bot.channel_id, message_id: post.telegram_message_id)

      {
        views: rand(100..1000),
        forwards: rand(5..50),
        reactions: {
          '👍' => rand(10..100),
          '❤️' => rand(5..50),
          '🔥' => rand(2..20)
        },
        button_clicks: {}
      }
    end
  end
end
