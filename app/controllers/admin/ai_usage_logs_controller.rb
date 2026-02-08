# frozen_string_literal: true

module Admin
  class AiUsageLogsController < Admin::ApplicationController
    def index
      @logs = AiUsageLog.includes(:user, :project)
                        .order(created_at: :desc)

      # Фильтрация
      @logs = @logs.where(user_id: params[:user_id]) if params[:user_id].present?
      @logs = @logs.where(model_used: params[:model]) if params[:model].present?
      @logs = @logs.where(purpose: params[:purpose]) if params[:purpose].present?

      if params[:period].present?
        days = params[:period].to_i
        @logs = @logs.where('created_at > ?', days.days.ago) if days > 0
      end

      @logs = @logs.page(params[:page]).per(50)

      # Статистика
      base_scope = AiUsageLog.all
      base_scope = base_scope.where('created_at > ?', params[:period].to_i.days.ago) if params[:period].present? && params[:period].to_i > 0

      @stats = {
        total_requests: base_scope.count,
        total_tokens: base_scope.sum(:tokens_used),
        total_cost: base_scope.sum(:cost),
        models: base_scope.group(:model_used).count,
        purposes: base_scope.group(:purpose).count
      }

      @users = User.where(id: AiUsageLog.distinct.pluck(:user_id)).order(:email)
      @models = AiUsageLog.distinct.pluck(:model_used).compact.sort
    end
  end
end
