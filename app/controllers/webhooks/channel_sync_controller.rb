# frozen_string_literal: true

module Webhooks
  class ChannelSyncController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!, raise: false

    # POST /webhooks/channel_sync
    # Callback от Python microservice с результатами парсинга
    def receive
      channel_site_id = params[:channel_site_id]
      posts_data = params[:posts] || []
      status = params[:status]

      channel_site = ChannelSite.find_by(id: channel_site_id)

      unless channel_site
        render json: { error: "Channel site not found" }, status: :not_found
        return
      end

      if status == "success"
        result = ChannelSites::ImportPostsService.new(channel_site, posts_data).call

        Rails.logger.info(
          "Channel sync completed for site #{channel_site_id}: " \
          "imported=#{result[:imported]}, updated=#{result[:updated]}"
        )

        render json: {
          success: true,
          imported: result[:imported],
          updated: result[:updated]
        }
      else
        error_message = params[:error] || "Unknown error"
        Rails.logger.error("Channel sync failed for site #{channel_site_id}: #{error_message}")

        render json: { success: false, error: error_message }
      end
    rescue StandardError => e
      Rails.logger.error("Channel sync webhook error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render json: { error: e.message }, status: :internal_server_error
    end
  end
end
