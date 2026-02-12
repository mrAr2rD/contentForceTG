# frozen_string_literal: true

# Шаблоны уведомлений для разных типов событий
# Поддерживает переменные вида {{variable_name}}
class NotificationTemplate < ApplicationRecord
  # Валидации
  validates :event_type, presence: true
  validates :channel, presence: true
  validates :body_template, presence: true
  validates :event_type, uniqueness: { scope: :channel }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_channel, ->(channel) { where(channel: channel) }
  scope :for_event, ->(event_type) { where(event_type: event_type) }

  # Стандартные шаблоны
  DEFAULTS = {
    # Payment
    payment_success: {
      email: {
        subject: "Оплата прошла успешно",
        body: "Здравствуйте, {{user_name}}!\n\nВаш платёж на сумму {{amount}} ₽ успешно обработан.\n\nТариф: {{plan_name}}\nДействует до: {{expires_at}}\n\nСпасибо, что выбрали ContentForce!"
      },
      telegram: {
        body: "✅ *Платёж прошёл успешно!*\n\nСумма: {{amount}} ₽\nТариф: {{plan_name}}\nДействует до: {{expires_at}}"
      }
    },
    payment_failed: {
      email: {
        subject: "Ошибка оплаты",
        body: "Здравствуйте, {{user_name}}!\n\nК сожалению, платёж не удался.\n\nПричина: {{error_message}}\n\nПожалуйста, попробуйте ещё раз или свяжитесь с поддержкой."
      },
      telegram: {
        body: "❌ *Ошибка оплаты*\n\nПричина: {{error_message}}\n\nПожалуйста, попробуйте ещё раз."
      }
    },

    # Subscription
    subscription_expiring: {
      email: {
        subject: "Ваша подписка скоро истекает",
        body: "Здравствуйте, {{user_name}}!\n\nВаша подписка на тариф {{plan_name}} истекает {{expires_at}}.\n\nПродлите подписку, чтобы не потерять доступ к функциям."
      },
      telegram: {
        body: "⏰ *Подписка скоро истекает*\n\nТариф {{plan_name}} истекает {{expires_at}}.\n\nПродлите подписку, чтобы продолжить пользоваться сервисом."
      }
    },
    subscription_expired: {
      email: {
        subject: "Ваша подписка истекла",
        body: "Здравствуйте, {{user_name}}!\n\nВаша подписка на тариф {{plan_name}} истекла.\n\nВы можете продлить подписку в любое время."
      },
      telegram: {
        body: "⚠️ *Подписка истекла*\n\nВаш тариф {{plan_name}} больше не активен.\n\nПродлите подписку для восстановления доступа."
      }
    },

    # Usage limits
    usage_limit_warning: {
      email: {
        subject: "Лимит использования почти исчерпан",
        body: "Здравствуйте, {{user_name}}!\n\nВы использовали {{usage_percent}}% лимита {{feature_name}} в этом месяце.\n\nОсталось: {{remaining}} из {{limit}}"
      },
      telegram: {
        body: "⚠️ *Лимит почти исчерпан*\n\n{{feature_name}}: {{usage_percent}}% использовано\nОсталось: {{remaining}} из {{limit}}"
      }
    },
    usage_limit_reached: {
      email: {
        subject: "Лимит использования исчерпан",
        body: "Здравствуйте, {{user_name}}!\n\nВы достигли лимита {{feature_name}} в этом месяце.\n\nДля продолжения работы перейдите на более высокий тариф."
      },
      telegram: {
        body: "🚫 *Лимит исчерпан*\n\n{{feature_name}} недоступен до конца месяца.\n\nПерейдите на более высокий тариф для снятия ограничений."
      }
    },

    # Posts
    post_published: {
      telegram: {
        body: "✅ *Пост опубликован*\n\nКанал: {{channel_name}}\nПросмотры: {{views}}"
      }
    },
    post_failed: {
      email: {
        subject: "Ошибка публикации поста",
        body: "Здравствуйте, {{user_name}}!\n\nНе удалось опубликовать пост в канал {{channel_name}}.\n\nОшибка: {{error_message}}"
      },
      telegram: {
        body: "❌ *Ошибка публикации*\n\nКанал: {{channel_name}}\nОшибка: {{error_message}}"
      }
    }
  }.freeze

  # Найти шаблон для события и канала
  def self.find_for(event_type:, channel:)
    active.for_event(event_type).for_channel(channel).first
  end

  # Рендерит шаблон с подстановкой переменных
  def render(context = {})
    rendered_body = body_template.dup
    rendered_subject = subject&.dup

    context.each do |key, value|
      placeholder = "{{#{key}}}"
      rendered_body.gsub!(placeholder, value.to_s)
      rendered_subject&.gsub!(placeholder, value.to_s)
    end

    {
      subject: rendered_subject,
      body: rendered_body
    }
  end
end
