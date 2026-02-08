# frozen_string_literal: true

module ChannelSites
  class ImportPostsService
    def initialize(channel_site, posts_data)
      @channel_site = channel_site
      @posts_data = posts_data
    end

    def call
      imported_count = 0
      updated_count = 0
      errors = []

      @posts_data.each do |post_data|
        result = import_post(post_data)

        case result[:status]
        when :created
          imported_count += 1
        when :updated
          updated_count += 1
        when :error
          errors << result[:error]
        end
      end

      @channel_site.update_posts_count!

      {
        success: errors.empty?,
        imported: imported_count,
        updated: updated_count,
        errors: errors
      }
    end

    private

    def import_post(data)
      post = @channel_site.channel_posts.find_or_initialize_by(
        telegram_message_id: data["message_id"]
      )

      is_new = post.new_record?

      post.assign_attributes(
        telegram_date: parse_date(data["date"]),
        original_text: data["text"],
        media: data["media"] || [],
        views_count: data["views"] || 0
      )

      if post.save
        { status: is_new ? :created : :updated }
      else
        { status: :error, error: "Message #{data['message_id']}: #{post.errors.full_messages.join(', ')}" }
      end
    rescue StandardError => e
      { status: :error, error: "Message #{data['message_id']}: #{e.message}" }
    end

    def parse_date(date_value)
      case date_value
      when Integer
        Time.at(date_value).utc
      when String
        Time.parse(date_value).utc
      else
        Time.current
      end
    end
  end
end
