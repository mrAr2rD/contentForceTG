# frozen_string_literal: true

module Analytics
  # Сервис расчёта ROI (Return on Investment)
  # Сравнивает расходы на AI с доходами от подписок
  class RoiCalculatorService
    def initialize(period: 30.days)
      @period = period
      @from = period.ago
      @to = Time.current
      @has_cost_column = check_cost_column
      @has_detailed_costs = @has_cost_column && check_detailed_costs_columns
    end

    # Основной метод расчёта
    def calculate
      {
        period: {
          from: @from,
          to: @to,
          days: (@to - @from).to_i / 1.day.to_i
        },
        ai_costs: ai_costs_data,
        revenue: revenue_data,
        roi: calculate_roi,
        breakdown_by_model: costs_by_model,
        breakdown_by_provider: costs_by_provider,
        daily_stats: daily_stats,
        migrations_pending: !@has_cost_column || !@has_detailed_costs
      }
    end

    # Общие расходы на AI
    def total_ai_costs
      return 0 unless @has_cost_column

      base_cost = ai_usage_logs.sum(:cost)
      return base_cost unless @has_detailed_costs

      base_cost + ai_usage_logs.sum(:input_cost).to_f + ai_usage_logs.sum(:output_cost).to_f
    end

    # Общие доходы
    def total_revenue
      completed_payments.sum(:amount)
    end

    private

    def ai_usage_logs
      @ai_usage_logs ||= AiUsageLog.where(created_at: @from..@to)
    end

    def completed_payments
      @completed_payments ||= Payment.where(status: :completed, created_at: @from..@to)
    end

    def ai_costs_data
      total = total_ai_costs
      data = {
        total: total.round(2),
        total_usd: total.round(6),
        total_rub: (total * usd_to_rub_rate).round(2),
        requests_count: ai_usage_logs.count,
        tokens_used: @has_cost_column ? ai_usage_logs.sum(:tokens_used) : 0,
        average_cost_per_request: average_cost_per_request
      }

      if @has_detailed_costs
        data[:input_tokens] = ai_usage_logs.sum(:input_tokens)
        data[:output_tokens] = ai_usage_logs.sum(:output_tokens)
      end

      data
    end

    def revenue_data
      {
        total: total_revenue.round(2),
        payments_count: completed_payments.count,
        average_payment: average_payment,
        by_plan: revenue_by_plan
      }
    end

    def calculate_roi
      costs_rub = total_ai_costs * usd_to_rub_rate
      return Float::INFINITY if costs_rub.zero?

      profit = total_revenue - costs_rub
      roi_percent = (profit / costs_rub * 100).round(2)

      {
        profit: profit.round(2),
        roi_percent: roi_percent,
        profitable: profit > 0
      }
    end

    def costs_by_model
      return [] unless @has_cost_column

      cost_expression = if @has_detailed_costs
                          "SUM(cost) + SUM(COALESCE(input_cost, 0)) + SUM(COALESCE(output_cost, 0)) as cost_total"
      else
                          "SUM(cost) as cost_total"
      end

      ai_usage_logs
        .group(:model_used)
        .select(
          "model_used",
          "COUNT(*) as requests_count",
          "SUM(tokens_used) as total_tokens",
          cost_expression
        )
        .map do |record|
          {
            model: record.model_used,
            requests_count: record.requests_count,
            total_tokens: record.total_tokens,
            total_cost: record.cost_total.to_f.round(6)
          }
        end
        .sort_by { |r| -r[:total_cost] }
    end

    def costs_by_provider
      model_costs = costs_by_model
      providers = {}

      model_costs.each do |model_data|
        ai_model = AiModel.find_by(model_id: model_data[:model])
        provider = ai_model&.provider || extract_provider(model_data[:model])

        providers[provider] ||= { requests: 0, tokens: 0, cost: 0 }
        providers[provider][:requests] += model_data[:requests_count]
        providers[provider][:tokens] += model_data[:total_tokens]
        providers[provider][:cost] += model_data[:total_cost]
      end

      providers.map { |name, data| data.merge(provider: name) }
               .sort_by { |r| -r[:cost] }
    end

    def daily_stats
      # Получаем дневную статистику
      costs_by_day = if @has_cost_column
                       cost_expression = if @has_detailed_costs
                                           "cost + COALESCE(input_cost, 0) + COALESCE(output_cost, 0)"
                       else
                                           "cost"
                       end
                       ai_usage_logs.group("DATE(created_at)").sum(cost_expression)
      else
                       {}
      end

      revenue_by_day = completed_payments
        .group("DATE(created_at)")
        .sum(:amount)

      # Объединяем данные по дням
      all_dates = (costs_by_day.keys + revenue_by_day.keys).uniq.sort

      all_dates.map do |date|
        {
          date: date,
          ai_cost_usd: (costs_by_day[date] || 0).round(6),
          ai_cost_rub: ((costs_by_day[date] || 0) * usd_to_rub_rate).round(2),
          revenue: (revenue_by_day[date] || 0).round(2)
        }
      end
    end

    def revenue_by_plan
      completed_payments
        .joins(subscription: :plan_record)
        .group("plans.name")
        .sum(:amount)
    rescue ActiveRecord::StatementInvalid
      # Fallback если план ещё не привязан
      completed_payments
        .joins(:subscription)
        .group("subscriptions.plan")
        .sum(:amount)
    end

    def average_cost_per_request
      count = ai_usage_logs.count
      return 0 if count.zero?
      (total_ai_costs / count).round(6)
    end

    def average_payment
      count = completed_payments.count
      return 0 if count.zero?
      (total_revenue / count).round(2)
    end

    def extract_provider(model_id)
      model_id.to_s.split("/").first&.titleize || "Unknown"
    end

    # Курс USD к RUB (можно сделать настраиваемым)
    def usd_to_rub_rate
      @usd_to_rub_rate ||= ENV.fetch("USD_TO_RUB_RATE", 90).to_f
    end

    # Проверяем, есть ли базовая колонка cost
    def check_cost_column
      AiUsageLog.table_exists? && AiUsageLog.column_names.include?("cost")
    rescue StandardError
      false
    end

    # Проверяем, есть ли колонки для детальных расходов
    def check_detailed_costs_columns
      AiUsageLog.column_names.include?("input_cost")
    rescue StandardError
      false
    end
  end
end
