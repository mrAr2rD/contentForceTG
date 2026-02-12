# frozen_string_literal: true

module Webhooks
  class StyleImportController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      Rails.logger.info "[STYLE_IMPORT] Webhook received: #{params.except(:posts).inspect}"
      Rails.logger.info "[STYLE_IMPORT] Posts count: #{params[:posts]&.size || 0}"

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
          original_date: post_data[:date] ? Time.zone.at(post_data[:date]) : nil,
          metadata: {
            views: post_data[:views],
            forwards: post_data[:forwards],
            media_type: extract_media_type(post_data[:media])
          }
        )

        if sample.save
          imported_count += 1
        end
      end

      # Отправляем Turbo Stream обновление пользователю
      Turbo::StreamsChannel.broadcast_replace_to(
        "project_#{project.id}",
        target: "import_status",
        partial: "projects/style_samples/import_status",
        locals: {
          status: :success,
          imported_count: imported_count,
          channel: channel_username
        }
      )

      # Обновляем статистику
      Turbo::StreamsChannel.broadcast_replace_to(
        "project_#{project.id}",
        target: "style_stats",
        partial: "projects/style_settings/stats",
        locals: { project: project.reload }
      )

      # Обновляем список образцов
      Turbo::StreamsChannel.broadcast_prepend_to(
        "project_#{project.id}",
        target: "style_samples_list",
        partial: "projects/style_samples/sample_list",
        locals: { samples: project.style_samples.order(created_at: :desc).limit(imported_count) }
      )

      render json: {
        success: true,
        imported_count: imported_count,
        total_posts: posts.size
      }
    end

    private

    def extract_media_type(media_array)
      return nil if media_array.blank?

      # Берём первый элемент медиа и извлекаем тип
      first_media = media_array.first
      return nil unless first_media.is_a?(Hash)

      # Конвертируем MessageMediaPhoto -> photo, MessageMediaDocument -> document и т.д.
      media_type = first_media[:type] || first_media["type"]
      return nil if media_type.blank?

      media_type.to_s.gsub("MessageMedia", "").underscore
    end
  end
end
