# frozen_string_literal: true

module Notifications
  # Сервис для отправки уведомлений
  # Находит шаблоны, рендерит и создаёт уведомления
  class DispatcherService
    def initialize(user:, event_type:, context: {})
      @user = user
      @event_type = event_type
      @context = default_context.merge(context)
    end

    # Отправить уведомления по всем каналам
    def dispatch!
      results = []

      # Email уведомление
      if should_send_email?
        results << dispatch_to_channel(:email)
      end

      # Telegram уведомление
      if should_send_telegram?
        results << dispatch_to_channel(:telegram)
      end

      results.compact
    end

    # Отправить в конкретный канал
    def dispatch_to_channel(channel)
      template = find_template(channel)
      return nil unless template

      rendered = template.render(@context)

      notification = ::Notification.create!(
        user: @user,
        notification_type: @event_type,
        channel: channel,
        subject: rendered[:subject],
        body: rendered[:body],
        metadata: {
          template_id: template.id,
          context: @context.except(:user)
        }
      )

      notification
    rescue StandardError => e
      Rails.logger.error("Failed to dispatch #{@event_type} to #{channel}: #{e.message}")
      nil
    end

    # Класс-метод для удобного вызова
    def self.dispatch!(user:, event_type:, context: {})
      new(user: user, event_type: event_type, context: context).dispatch!
    end

    private

    def find_template(channel)
      NotificationTemplate.find_for(
        event_type: @event_type,
        channel: channel.to_s
      )
    end

    def default_context
      {
        user_name: @user.first_name || @user.email.split("@").first,
        user_email: @user.email
      }
    end

    def should_send_email?
      @user.email.present?
    end

    def should_send_telegram?
      @user.telegram_id.present?
    end
  end
end
