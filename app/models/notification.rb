# frozen_string_literal: true

# Модель уведомлений пользователям
# Поддерживает email и telegram каналы
class Notification < ApplicationRecord
  belongs_to :user

  # Enums
  enum :status, { pending: "pending", sent: "sent", failed: "failed", read: "read" }, default: :pending
  enum :channel, { email: "email", telegram: "telegram" }, default: :email

  # Типы уведомлений
  TYPES = %w[
    payment_success
    payment_failed
    subscription_activated
    subscription_expiring
    subscription_expired
    subscription_canceled
    usage_limit_warning
    usage_limit_reached
    channel_new_subscriber
    channel_subscriber_left
    post_published
    post_failed
  ].freeze

  # Валидации
  validates :notification_type, presence: true, inclusion: { in: TYPES }
  validates :channel, presence: true
  validates :body, presence: true

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }
  scope :pending_delivery, -> { where(status: :pending) }
  scope :failed_delivery, -> { where(status: :failed) }

  # Callbacks
  after_create :schedule_delivery

  # Отметить как прочитанное
  def mark_as_read!
    update!(read_at: Time.current, status: :read)
  end

  # Отметить как отправленное
  def mark_as_sent!
    update!(sent_at: Time.current, status: :sent)
  end

  # Отметить как ошибку
  def mark_as_failed!(error_message = nil)
    update!(
      status: :failed,
      metadata: metadata.merge("error" => error_message)
    )
  end

  # Прочитано ли
  def read?
    read_at.present?
  end

  private

  # Планируем отправку уведомления
  def schedule_delivery
    case channel
    when "email"
      NotificationMailer.deliver_notification(self).deliver_later
    when "telegram"
      SendTelegramNotificationJob.perform_later(id)
    end
  rescue StandardError => e
    Rails.logger.error("Failed to schedule notification #{id}: #{e.message}")
  end
end
