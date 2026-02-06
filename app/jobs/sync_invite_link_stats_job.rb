# frozen_string_literal: true

# Job для синхронизации статистики пригласительных ссылок
# Запускается по cron каждый час
class SyncInviteLinkStatsJob < ApplicationJob
  queue_as :default

  def perform(telegram_bot_id = nil)
    if telegram_bot_id
      sync_bot_links(TelegramBot.find(telegram_bot_id))
    else
      sync_all_bots
    end
  end

  private

  def sync_all_bots
    TelegramBot.verified.find_each do |bot|
      sync_bot_links(bot)
    rescue StandardError => e
      Rails.logger.error("Failed to sync invite links for bot #{bot.id}: #{e.message}")
    end
  end

  def sync_bot_links(bot)
    service = Telegram::InviteLinkService.new(bot)
    service.sync_all_links_stats

    Rails.logger.info("Synced invite link stats for bot #{bot.id}")
  end
end
