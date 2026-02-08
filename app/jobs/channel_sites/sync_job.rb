# frozen_string_literal: true

module ChannelSites
  class SyncJob < ApplicationJob
    queue_as :default

    def perform(channel_site_id)
      channel_site = ChannelSite.find(channel_site_id)

      result = SyncService.new(channel_site).call

      if result[:success]
        Rails.logger.info("ChannelSites::SyncJob: Started sync for site #{channel_site_id}")
      else
        Rails.logger.error("ChannelSites::SyncJob: Failed for site #{channel_site_id}: #{result[:error]}")
      end
    end
  end
end
