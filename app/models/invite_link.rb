# frozen_string_literal: true

# Пригласительные ссылки для Telegram каналов
# Позволяют отслеживать источники трафика
class InviteLink < ApplicationRecord
  belongs_to :telegram_bot
  has_many :subscriber_events, dependent: :nullify

  # Валидации
  validates :invite_link, presence: true, uniqueness: true

  # Scopes
  scope :active, -> { where(revoked: false).where('expire_date IS NULL OR expire_date > ?', Time.current) }
  scope :expired, -> { where('expire_date <= ?', Time.current) }
  scope :revoked, -> { where(revoked: true) }
  scope :by_source, ->(source) { where(source: source) }
  scope :with_joins, -> { where('join_count > 0') }

  # Делегирование
  delegate :channel_name, to: :telegram_bot, allow_nil: true

  # Истекла ли ссылка
  def expired?
    expire_date.present? && expire_date <= Time.current
  end

  # Активна ли ссылка
  def active?
    !revoked? && !expired? && (!member_limit || join_count < member_limit)
  end

  # Достигнут ли лимит
  def limit_reached?
    member_limit.present? && join_count >= member_limit
  end

  # Конверсия (процент тех, кто остался в канале)
  def conversion_rate
    return 0.0 if join_count.zero?

    stayed = subscriber_events.where(event_type: 'joined').count -
             subscriber_events.where(event_type: %w[left kicked]).count

    ((stayed.to_f / join_count) * 100).round(2)
  end

  # Статистика по ссылке
  def stats
    {
      join_count: join_count,
      current_subscribers: current_subscribers_count,
      left_count: left_count,
      conversion_rate: conversion_rate,
      active: active?
    }
  end

  # Текущее количество подписчиков по этой ссылке
  def current_subscribers_count
    joins = subscriber_events.where(event_type: 'joined').count
    leaves = subscriber_events.where(event_type: %w[left kicked]).count
    [joins - leaves, 0].max
  end

  # Количество ушедших
  def left_count
    subscriber_events.where(event_type: %w[left kicked]).count
  end

  # Увеличить счётчик
  def increment_join_count!
    increment!(:join_count)
  end

  # Отозвать ссылку
  def revoke!
    update!(revoked: true)
  end
end
