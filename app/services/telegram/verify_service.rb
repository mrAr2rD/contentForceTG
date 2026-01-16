# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Telegram
  class VerifyService
    def initialize(telegram_bot)
      @bot = telegram_bot
    end

    def verify!
      # 1. Проверяем токен через Telegram API
      bot_info = get_bot_info
      
      @bot.update!(
        bot_username: bot_info['username'],
        verified: true,
        verified_at: Time.current
      )

      # 2. Проверяем права в канале (если указан)
      if @bot.channel_id.present?
        verify_channel_permissions
      end

      true
    rescue StandardError => e
      @bot.update!(
        verified: false,
        verified_at: nil
      )
      raise e
    end

    private

    def get_bot_info
      response = make_request('getMe')
      
      unless response['ok']
        raise "Invalid bot token: #{response['description']}"
      end

      response['result']
    end

    def verify_channel_permissions
      channel_id = @bot.channel_id.to_s
      unless channel_id.start_with?('@') || channel_id.match?(/\A-?\d+\z/)
        raise "Invalid channel format. It should be a numeric ID (e.g., -1001234567890) or a username (e.g., @my_channel)."
      end

      response = make_request('getChat', { chat_id: channel_id })

      unless response['ok']
        error_message = "Cannot access channel: #{response['description']}."
        if channel_id.start_with?('@')
          error_message += " Make sure the bot is an administrator in the channel."
        else
          error_message += " Make sure the chat ID is correct and the bot has been added to the channel."
        end
        raise error_message
      end

      chat = response['result']
      @bot.update!(channel_name: chat['title'])

      # Проверяем права бота в канале
      member_response = make_request('getChatMember', {
        chat_id: channel_id,
        user_id: get_bot_info['id']
      })

      if member_response['ok']
        member = member_response['result']
        unless can_post_messages?(member)
          raise "Bot doesn't have permission to post messages in this channel"
        end
      else
        # This part might be redundant if getChat already failed, but good for robustness
        raise "Could not get chat member info: #{member_response['description']}. Is the bot a member of the channel?"
      end
    end

    def can_post_messages?(member)
      member['status'] == 'administrator' && 
        (member['can_post_messages'] == true || member['can_post_messages'].nil?)
    end

    def make_request(method, params = {})
      uri = URI("https://api.telegram.org/bot#{@bot.bot_token}/#{method}")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = params.to_json unless params.empty?
      
      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError => e
      { 'ok' => false, 'description' => e.message }
    end
  end
end
