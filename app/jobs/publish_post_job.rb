# frozen_string_literal: true

class PublishPostJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(post_id)
    post = Post.find(post_id)
    return unless post.scheduled? || post.draft?

    # Post#publish! handles status update, published_at, and telegram_message_id
    # No need to update here - it would cause race condition
    post.publish!
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("Post #{post_id} not found: #{e.message}")
  end
end
