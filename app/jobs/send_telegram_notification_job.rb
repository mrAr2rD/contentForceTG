# frozen_string_literal: true

# Job для отправки Telegram уведомлений пользователям
class SendTelegramNotificationJob < ApplicationJob
  queue_as :notifications

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(notification_id)
    notification = Notification.find_by(id: notification_id)
    return unless notification
    return if notification.sent?
    return unless notification.telegram?

    user = notification.user
    return notification.mark_as_failed!('User has no Telegram ID') unless user.telegram_id

    # Отправляем через любого бота пользователя
    bot = find_user_bot(user)
    return notification.mark_as_failed!('No verified bot found') unless bot

    send_message(bot, user.telegram_id, notification)
  end

  private

  def find_user_bot(user)
    # Ищем первого верифицированного бота пользователя
    user.projects
        .joins(:telegram_bots)
        .where(telegram_bots: { verified: true })
        .first
        &.telegram_bots
        &.verified
        &.first
  end

  def send_message(bot, chat_id, notification)
    uri = URI("https://api.telegram.org/bot#{bot.bot_token}/sendMessage")

    params = {
      chat_id: chat_id,
      text: notification.body,
      parse_mode: 'Markdown'
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = params.to_json

    response = http.request(request)
    result = JSON.parse(response.body)

    if result['ok']
      notification.mark_as_sent!
    else
      notification.mark_as_failed!(result['description'])
    end
  rescue StandardError => e
    notification.mark_as_failed!(e.message)
    raise
  end
end
