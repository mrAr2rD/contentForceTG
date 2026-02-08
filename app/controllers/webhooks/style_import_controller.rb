# frozen_string_literal: true

module Webhooks
  class StyleImportController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      project_id = params[:project_id]
      posts = params[:posts] || []
      channel_username = params[:channel_username]

      project = Project.find_by(id: project_id)

      unless project
        render json: { error: "Project not found" }, status: :not_found
        return
      end

      imported_count = 0

      posts.each do |post_data|
        next if post_data[:text].blank? || post_data[:text].length < 50

        sample = project.style_samples.find_or_initialize_by(
          telegram_message_id: post_data[:message_id]
        )

        sample.assign_attributes(
          content: post_data[:text],
          source_type: "telegram_import",
          source_channel: channel_username,
          original_date: post_data[:date] ? Time.zone.parse(post_data[:date]) : nil,
          metadata: {
            views: post_data[:views],
            forwards: post_data[:forwards],
            media_type: post_data[:media_type]
          }
        )

        if sample.save
          imported_count += 1
        end
      end

      render json: {
        success: true,
        imported_count: imported_count,
        total_posts: posts.size
      }
    end
  end
end
