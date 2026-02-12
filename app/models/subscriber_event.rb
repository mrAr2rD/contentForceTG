# frozen_string_literal: true

# События подписчиков канала
# Отслеживает подписки, отписки, баны
class SubscriberEvent < ApplicationRecord
  belongs_to :telegram_bot
  belongs_to :invite_link, optional: true

  # Типы событий
  EVENT_TYPES = %w[joined left kicked banned restricted].freeze

  # Валидации
  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :telegram_user_id, presence: true
  validates :event_at, presence: true

  # Scopes
  scope :joined, -> { where(event_type: "joined") }
  scope :left_channel, -> { where(event_type: "left") }
  scope :kicked, -> { where(event_type: "kicked") }
  scope :banned, -> { where(event_type: "banned") }

  scope :today, -> { where("event_at >= ?", Time.current.beginning_of_day) }
  scope :this_week, -> { where("event_at >= ?", 1.week.ago) }
  scope :this_month, -> { where("event_at >= ?", 1.month.ago) }

  scope :by_date_range, ->(from, to) { where(event_at: from..to) }
  scope :recent, -> { order(event_at: :desc) }
  scope :for_user, ->(telegram_user_id) { where(telegram_user_id: telegram_user_id) }

  # Делегирование
  delegate :channel_name, to: :telegram_bot, allow_nil: true

  # Callbacks
  before_validation :set_event_at

  # Отображаемое имя пользователя
  def display_name
    return username if username.present?
    return first_name if first_name.present?
    "User #{telegram_user_id}"
  end

  # Это подписка?
  def join?
    event_type == "joined"
  end

  # Это отписка?
  def leave?
    event_type == "left"
  end

  # Создать событие из webhook данных
  def self.create_from_webhook(telegram_bot:, update:)
    chat_member = update.dig("chat_member") || update.dig("my_chat_member")
    return unless chat_member

    new_status = chat_member.dig("new_chat_member", "status")
    old_status = chat_member.dig("old_chat_member", "status")
    user = chat_member.dig("new_chat_member", "user") || chat_member.dig("from")

    return unless user

    event_type = determine_event_type(old_status, new_status)
    return unless event_type

    # Попытка найти invite_link
    invite_link_url = chat_member.dig("invite_link", "invite_link")
    invite_link = InviteLink.find_by(invite_link: invite_link_url) if invite_link_url

    create!(
      telegram_bot: telegram_bot,
      invite_link: invite_link,
      telegram_user_id: user["id"],
      username: user["username"],
      first_name: user["first_name"],
      event_type: event_type,
      event_at: Time.at(chat_member["date"] || Time.current.to_i),
      user_data: {
        last_name: user["last_name"],
        language_code: user["language_code"],
        is_premium: user["is_premium"]
      }
    )
  end

  # Статистика за период
  def self.stats_for_period(from:, to:)
    events = by_date_range(from, to)
    {
      total_joins: events.joined.count,
      total_leaves: events.left_channel.count,
      total_kicks: events.kicked.count,
      net_growth: events.joined.count - events.left_channel.count - events.kicked.count,
      by_day: events.group_by_day(:event_at).count
    }
  end

  private

  def set_event_at
    self.event_at ||= Time.current
  end

  # Определяем тип события по изменению статуса
  def self.determine_event_type(old_status, new_status)
    # Пользователь вступил в канал
    if %w[left kicked].include?(old_status) && %w[member administrator creator].include?(new_status)
      return "joined"
    end

    # Пользователь покинул канал
    return "left" if %w[member administrator].include?(old_status) && new_status == "left"

    # Пользователь был кикнут
    return "kicked" if %w[member administrator].include?(old_status) && new_status == "kicked"

    # Пользователь был забанен
    return "banned" if new_status == "banned"

    # Пользователь был ограничен
    return "restricted" if new_status == "restricted"

    nil
  end
end
