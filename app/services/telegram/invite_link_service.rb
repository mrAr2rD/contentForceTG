# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Telegram
  # Сервис для работы с пригласительными ссылками Telegram
  class InviteLinkService
    def initialize(telegram_bot)
      @bot = telegram_bot
    end

    # Создать пригласительную ссылку
    def create_invite_link(name: nil, source: nil, member_limit: nil, expire_date: nil, creates_join_request: false)
      params = {
        chat_id: @bot.channel_id
      }

      params[:name] = name if name.present?
      params[:member_limit] = member_limit if member_limit.present?
      params[:expire_date] = expire_date.to_i if expire_date.present?
      params[:creates_join_request] = creates_join_request

      result = make_request('createChatInviteLink', params)

      if result['ok']
        invite_link_data = result['result']

        InviteLink.create!(
          telegram_bot: @bot,
          invite_link: invite_link_data['invite_link'],
          name: name || invite_link_data['name'],
          source: source,
          member_limit: member_limit,
          expire_date: expire_date,
          creates_join_request: creates_join_request
        )
      else
        raise "Failed to create invite link: #{result['description']}"
      end
    end

    # Отозвать пригласительную ссылку
    def revoke_invite_link(invite_link)
      result = make_request('revokeChatInviteLink', {
        chat_id: @bot.channel_id,
        invite_link: invite_link.invite_link
      })

      if result['ok']
        invite_link.revoke!
        true
      else
        raise "Failed to revoke invite link: #{result['description']}"
      end
    end

    # Получить информацию о ссылке
    def get_invite_link_info(invite_link_str)
      # Telegram не предоставляет метод для получения информации о ссылке,
      # но мы можем использовать getChatMemberCount для проверки
      result = make_request('getChatMemberCount', {
        chat_id: @bot.channel_id
      })

      result['ok'] ? result['result'] : nil
    end

    # Экспортировать ссылку на канал (основную)
    def export_chat_invite_link
      result = make_request('exportChatInviteLink', {
        chat_id: @bot.channel_id
      })

      result['ok'] ? result['result'] : nil
    end

    # Синхронизировать статистику всех ссылок канала
    def sync_all_links_stats
      @bot.invite_links.active.find_each do |link|
        sync_link_stats(link)
      end
    end

    # Синхронизировать статистику конкретной ссылки
    def sync_link_stats(invite_link)
      # Подсчитываем события по ссылке
      joins = invite_link.subscriber_events.joins.count
      leaves = invite_link.subscriber_events.where(event_type: %w[left kicked]).count

      invite_link.update!(
        join_count: joins
      )
    end

    private

    def make_request(method, params = {})
      uri = URI("https://api.telegram.org/bot#{@bot.bot_token}/#{method}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = params.to_json

      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError => e
      { 'ok' => false, 'description' => e.message }
    end
  end
end
