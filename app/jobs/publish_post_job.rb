# frozen_string_literal: true

class PublishPostJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(post_id)
    post = Post.find(post_id)
    return unless post.scheduled? || post.draft?

    result = post.publish!

    # Обновляем статус и message_id
    post.update!(
      status: :published,
      published_at: Time.current,
      telegram_message_id: result.message_id
    )

    # Запускаем обновление аналитики в фоне
    # Analytics::UpdatePostViewsJob.perform_later(post.telegram_bot_id) if defined?(Analytics::UpdatePostViewsJob)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("Post #{post_id} not found: #{e.message}")
  rescue StandardError => e
    post&.update!(status: :failed)
    Rails.logger.error("Failed to publish post #{post_id}: #{e.message}")
    raise
  end
end
