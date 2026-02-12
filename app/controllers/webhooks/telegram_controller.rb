# frozen_string_literal: true

module Webhooks
  class TelegramController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!, raise: false
    before_action :verify_webhook_signature

    def receive
      bot_token = params[:bot_token]
      telegram_bot = TelegramBot.find_by(bot_token: bot_token)

      unless telegram_bot
        render json: { error: "Bot not found" }, status: :not_found
        return
      end

      # Обрабатываем webhook данные
      update = params.permit!.to_h.except(:controller, :action, :bot_token)

      # Логируем для отладки
      Rails.logger.info("Telegram webhook received for bot #{telegram_bot.id}: #{update.keys}")

      # Обработка различных типов обновлений
      process_channel_post(telegram_bot, update["channel_post"]) if update["channel_post"].present?
      process_edited_channel_post(telegram_bot, update["edited_channel_post"]) if update["edited_channel_post"].present?
      process_message_reaction(telegram_bot, update["message_reaction"]) if update["message_reaction"].present?
      process_chat_member(telegram_bot, update["my_chat_member"]) if update["my_chat_member"].present?
      process_chat_member(telegram_bot, update["chat_member"]) if update["chat_member"].present?
      process_callback_query(telegram_bot, update["callback_query"]) if update["callback_query"].present?

      head :ok
    rescue StandardError => e
      Rails.logger.error("Telegram webhook error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      head :ok # Всегда возвращаем 200, чтобы Telegram не повторял
    end

    private

    # Process channel posts (when our bot posts to channel)
    def process_channel_post(bot, post_data)
      message_id = post_data["message_id"]
      views = post_data["views"] || 0

      # Сохраняем пост для мини-сайта (если есть channel_site)
      save_channel_post_for_site(bot, post_data)

      # Find our post by message_id (для аналитики наших постов)
      post = bot.posts.find_by(telegram_message_id: message_id)
      return unless post

      # Update or create analytics record
      update_post_analytics(post, {
        views: views,
        forwards: post_data["forward_count"] || 0,
        measured_at: Time.current
      })

      Rails.logger.info("Updated analytics for post #{post.id} from channel_post webhook")
    end

    # Process edited channel posts (view count updates)
    def process_edited_channel_post(bot, post_data)
      message_id = post_data["message_id"]
      views = post_data["views"] || 0

      post = bot.posts.find_by(telegram_message_id: message_id)
      return unless post

      # This often contains updated view counts
      update_post_analytics(post, {
        views: views,
        forwards: post_data["forward_count"] || 0,
        measured_at: Time.current
      })

      Rails.logger.info("Updated analytics for post #{post.id} from edited_channel_post webhook (views: #{views})")
    end

    # Process message reactions (likes, hearts, etc.)
    def process_message_reaction(bot, reaction_data)
      message_id = reaction_data["message_id"]
      chat_id = reaction_data["chat"]["id"]

      # Only process if it's our channel
      return unless chat_id.to_s == bot.channel_id

      post = bot.posts.find_by(telegram_message_id: message_id)
      return unless post

      # Get latest analytics or create new
      last_analytics = post.post_analytics.recent.first
      reactions_hash = last_analytics&.reactions || {}

      # Update reactions based on new/old reactions
      new_reactions = reaction_data["new_reaction"] || []
      old_reactions = reaction_data["old_reaction"] || []

      # Remove old reactions
      old_reactions.each do |reaction|
        emoji = reaction.dig("type", "emoji")
        reactions_hash[emoji] = [ reactions_hash[emoji].to_i - 1, 0 ].max if emoji
      end

      # Add new reactions
      new_reactions.each do |reaction|
        emoji = reaction.dig("type", "emoji")
        reactions_hash[emoji] = reactions_hash[emoji].to_i + 1 if emoji
      end

      # Clean up zero values
      reactions_hash.reject! { |_, count| count.zero? }

      update_post_analytics(post, {
        reactions: reactions_hash,
        measured_at: Time.current
      })

      Rails.logger.info("Updated reactions for post #{post.id}: #{reactions_hash}")
    end

    # Process chat member updates (joins/leaves)
    def process_chat_member(bot, member_data)
      chat = member_data["chat"]
      return unless chat["type"] == "channel"
      return unless chat["id"].to_s == bot.channel_id

      old_status = member_data.dig("old_chat_member", "status")
      new_status = member_data.dig("new_chat_member", "status")

      # Создаём событие подписчика для детальной аналитики
      create_subscriber_event(bot, member_data)

      # Track subscriber changes
      if subscriber_joined?(old_status, new_status)
        increment_subscriber_count(bot, 1)
        update_invite_link_stats(bot, member_data)
        Rails.logger.info("New subscriber for bot #{bot.id}")
      elsif subscriber_left?(old_status, new_status)
        increment_subscriber_count(bot, -1)
        Rails.logger.info("Lost subscriber for bot #{bot.id}")
      end
    end

    # Создать событие подписчика для детальной аналитики
    def create_subscriber_event(bot, member_data)
      SubscriberEvent.create_from_webhook(
        telegram_bot: bot,
        update: { "chat_member" => member_data }
      )
    rescue StandardError => e
      Rails.logger.error("Failed to create subscriber event: #{e.message}")
    end

    # Обновить статистику invite link при вступлении
    def update_invite_link_stats(bot, member_data)
      invite_link_url = member_data.dig("invite_link", "invite_link")
      return unless invite_link_url

      invite_link = InviteLink.find_by(invite_link: invite_link_url)
      return unless invite_link

      invite_link.increment_join_count!
      Rails.logger.info("Incremented join count for invite link #{invite_link.id}")
    rescue StandardError => e
      Rails.logger.error("Failed to update invite link stats: #{e.message}")
    end

    # Process callback queries (button clicks)
    def process_callback_query(bot, query_data)
      message = query_data["message"]
      return unless message

      message_id = message["message_id"]
      callback_data = query_data["data"]

      post = bot.posts.find_by(telegram_message_id: message_id)
      return unless post

      # Track button clicks
      last_analytics = post.post_analytics.recent.first
      button_clicks = last_analytics&.button_clicks || {}
      button_clicks[callback_data] = button_clicks[callback_data].to_i + 1

      update_post_analytics(post, {
        button_clicks: button_clicks,
        measured_at: Time.current
      })

      Rails.logger.info("Button click tracked for post #{post.id}: #{callback_data}")
    end

    # Helper: Update or create post analytics (с блокировкой для предотвращения race condition)
    def update_post_analytics(post, data)
      post.with_lock do
        last_analytics = post.post_analytics.recent.first

        # If last analytics was created within 5 minutes, update it
        # Otherwise create new record
        if last_analytics && last_analytics.measured_at > 5.minutes.ago
          last_analytics.update!(
            views: data[:views] || last_analytics.views,
            forwards: data[:forwards] || last_analytics.forwards,
            reactions: data[:reactions] || last_analytics.reactions || {},
            button_clicks: data[:button_clicks] || last_analytics.button_clicks || {},
            measured_at: data[:measured_at] || Time.current
          )
        else
          post.post_analytics.create!(
            telegram_message_id: post.telegram_message_id,
            views: data[:views] || last_analytics&.views || 0,
            forwards: data[:forwards] || last_analytics&.forwards || 0,
            reactions: data[:reactions] || last_analytics&.reactions || {},
            button_clicks: data[:button_clicks] || last_analytics&.button_clicks || {},
            measured_at: data[:measured_at] || Time.current
          )
        end
      end
    end

    # Helper: Increment subscriber count
    def increment_subscriber_count(bot, delta)
      last_metric = bot.channel_subscriber_metrics.recent.first
      current_count = last_metric&.subscriber_count || 0
      new_count = [ current_count + delta, 0 ].max

      # If last metric was created today, update it
      # Otherwise create new metric
      if last_metric && last_metric.measured_at > 1.hour.ago
        last_metric.update!(
          subscriber_count: new_count,
          subscriber_growth: last_metric.subscriber_growth + delta
        )
      else
        bot.channel_subscriber_metrics.create!(
          subscriber_count: new_count,
          subscriber_growth: delta,
          churn_rate: 0.0,
          measured_at: Time.current
        )
      end
    end

    # Helper: Check if subscriber joined
    def subscriber_joined?(old_status, new_status)
      non_member_statuses = %w[left kicked]
      member_statuses = %w[member administrator creator]

      non_member_statuses.include?(old_status) && member_statuses.include?(new_status)
    end

    # Helper: Check if subscriber left
    def subscriber_left?(old_status, new_status)
      member_statuses = %w[member administrator creator]
      non_member_statuses = %w[left kicked]

      member_statuses.include?(old_status) && non_member_statuses.include?(new_status)
    end

    # Helper: Проверка подписи webhook от Telegram
    def verify_webhook_signature
      bot_token = params[:bot_token]
      telegram_bot = TelegramBot.find_by(bot_token: bot_token)

      unless telegram_bot
        Rails.logger.warn("Webhook: Bot not found for token #{bot_token[0..10]}... IP: #{request.remote_ip}")
        head :not_found
        return
      end

      provided_token = request.headers["X-Telegram-Bot-Api-Secret-Token"]
      expected_token = telegram_bot.webhook_secret

      # Legacy mode: allow bots without secret during migration
      unless expected_token.present?
        Rails.logger.warn("Webhook: Bot #{telegram_bot.id} has no webhook secret (migration mode)")
        return
      end

      unless ActiveSupport::SecurityUtils.secure_compare(provided_token.to_s, expected_token.to_s)
        Rails.logger.error("Webhook: Invalid secret for bot #{telegram_bot.id}. IP: #{request.remote_ip}")
        head :unauthorized
      end
    end

    # Helper: Сохранить пост канала для мини-сайта
    def save_channel_post_for_site(bot, post_data)
      channel_site = bot.channel_site
      return unless channel_site&.enabled?

      message_id = post_data["message_id"]
      text = post_data["text"] || post_data["caption"] || ""

      # Пропускаем пустые посты
      return if text.blank? && post_data["photo"].blank? && post_data["video"].blank?

      # Собираем медиа
      media = []
      if post_data["photo"].present?
        # photo - массив размеров, берём последний (самый большой)
        largest_photo = post_data["photo"].is_a?(Array) ? post_data["photo"].last : post_data["photo"]
        media << {
          type: "photo",
          file_id: largest_photo["file_id"],
          width: largest_photo["width"],
          height: largest_photo["height"]
        }
      end

      if post_data["video"].present?
        media << {
          type: "video",
          file_id: post_data["video"]["file_id"],
          duration: post_data["video"]["duration"]
        }
      end

      if post_data["document"].present?
        media << {
          type: "document",
          file_id: post_data["document"]["file_id"],
          file_name: post_data["document"]["file_name"]
        }
      end

      # Создаём или обновляем пост
      channel_post = channel_site.channel_posts.find_or_initialize_by(
        telegram_message_id: message_id
      )

      channel_post.assign_attributes(
        telegram_date: post_data["date"] ? Time.at(post_data["date"]).utc : Time.current,
        original_text: text,
        media: media,
        views_count: post_data["views"] || 0
      )

      if channel_post.save
        channel_site.update_posts_count!
        Rails.logger.info("Saved channel post #{message_id} for site #{channel_site.id}")
      else
        Rails.logger.error("Failed to save channel post: #{channel_post.errors.full_messages.join(', ')}")
      end
    rescue StandardError => e
      Rails.logger.error("Error saving channel post for site: #{e.message}")
    end
  end
end
