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
  end
end
