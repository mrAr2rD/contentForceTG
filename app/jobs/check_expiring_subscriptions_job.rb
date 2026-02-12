# frozen_string_literal: true

# Job для проверки истекающих подписок и отправки уведомлений
# Запускается по cron ежедневно
class CheckExpiringSubscriptionsJob < ApplicationJob
  queue_as :default

  # Предупреждаем за 7 дней, 3 дня и 1 день до истечения
  NOTIFICATION_DAYS = [ 7, 3, 1 ].freeze

  def perform
    NOTIFICATION_DAYS.each do |days|
      check_expiring_in(days)
    end

    check_expired
  end

  private

  def check_expiring_in(days)
    target_date = days.days.from_now.to_date

    Subscription.active
                .where.not(plan: :free)
                .where(current_period_end: target_date.beginning_of_day..target_date.end_of_day)
                .find_each do |subscription|
      send_expiring_notification(subscription, days)
    end
  end

  def check_expired
    Subscription.active
                .where.not(plan: :free)
                .where("current_period_end < ?", Time.current)
                .find_each do |subscription|
      handle_expired_subscription(subscription)
    end
  end

  def send_expiring_notification(subscription, days_remaining)
    # Проверяем, не отправляли ли уже уведомление
    return if already_notified?(subscription.user, "subscription_expiring", days_remaining)

    Notifications::DispatcherService.dispatch!(
      user: subscription.user,
      event_type: "subscription_expiring",
      context: {
        plan_name: subscription.plan_name,
        expires_at: subscription.current_period_end.strftime("%d.%m.%Y"),
        days_remaining: days_remaining
      }
    )

    Rails.logger.info("Sent expiring notification to user #{subscription.user_id}, #{days_remaining} days remaining")
  end

  def handle_expired_subscription(subscription)
    return if already_notified?(subscription.user, "subscription_expired", 0)

    # Отправляем уведомление об истечении
    Notifications::DispatcherService.dispatch!(
      user: subscription.user,
      event_type: "subscription_expired",
      context: {
        plan_name: subscription.plan_name
      }
    )

    # Понижаем до бесплатного плана
    subscription.update!(plan: :free)

    Rails.logger.info("Subscription expired for user #{subscription.user_id}, downgraded to free")
  end

  def already_notified?(user, event_type, days)
    # Проверяем, было ли уведомление сегодня
    Notification.where(user: user, notification_type: event_type)
                .where("created_at >= ?", Time.current.beginning_of_day)
                .where("metadata->>'days_remaining' = ?", days.to_s)
                .exists?
  end
end
