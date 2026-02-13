# frozen_string_literal: true

module Admin
  # Дашборд аналитики аудитории — данные из онбординга
  class AudienceController < ApplicationController
    def index
      @period = params[:period].to_i
      @period = 30 unless [ 7, 30, 90, 0 ].include?(@period) # 0 = все время

      @date_from = @period.positive? ? @period.days.ago.beginning_of_day : nil

      # Базовый scope
      base_scope = @date_from ? User.where("created_at >= ?", @date_from) : User.all

      # Метрики
      @metrics = calculate_metrics(base_scope)

      # Данные для графиков
      @chart_data = {
        referral_sources: group_by_field(base_scope, :referral_source, User::REFERRAL_SOURCES),
        age_ranges: group_by_field(base_scope, :age_range, User::AGE_RANGES),
        occupations: group_by_field(base_scope, :occupation, User::OCCUPATIONS),
        company_sizes: group_by_field(base_scope, :company_size, User::COMPANY_SIZES),
        registrations_by_day: registrations_by_day(base_scope)
      }
    end

    private

    def calculate_metrics(scope)
      total = scope.count
      completed = scope.completed_onboarding.count
      skipped = scope.skipped_onboarding.count
      pending = scope.onboarding_pending.count

      {
        total: total,
        completed: completed,
        skipped: skipped,
        pending: pending,
        conversion_rate: total.positive? ? ((completed.to_f / total) * 100).round(1) : 0,
        new_today: scope.where("created_at >= ?", Time.current.beginning_of_day).count,
        new_this_week: scope.where("created_at >= ?", 7.days.ago.beginning_of_day).count
      }
    end

    def group_by_field(scope, field, labels)
      # Считаем только пользователей, заполнивших это поле
      counts = scope.where.not(field => [ nil, "" ]).group(field).count

      # Преобразуем в формат для графиков
      labels.map do |key, label|
        { key: key, label: label, count: counts[key] || 0 }
      end.sort_by { |item| -item[:count] }
    end

    def registrations_by_day(scope)
      days = @period.positive? ? @period : 30
      start_date = days.days.ago.to_date

      # Группируем регистрации по дням
      registrations = scope
        .where("created_at >= ?", start_date.beginning_of_day)
        .group("DATE(created_at)")
        .count

      # Заполняем пропущенные дни нулями
      (start_date..Date.current).map do |date|
        {
          date: date.strftime("%d.%m"),
          count: registrations[date.to_s] || registrations[date] || 0
        }
      end
    end
  end
end
