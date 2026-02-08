# frozen_string_literal: true

module Admin
  class NotificationsController < Admin::ApplicationController
    def index
      @notifications = Notification.includes(:user)
                                   .order(created_at: :desc)

      # Фильтрация
      @notifications = @notifications.where(user_id: params[:user_id]) if params[:user_id].present?
      @notifications = @notifications.where(notification_type: params[:type]) if params[:type].present?
      @notifications = @notifications.where(status: params[:status]) if params[:status].present?
      @notifications = @notifications.where(channel: params[:channel]) if params[:channel].present?

      @notifications = @notifications.page(params[:page]).per(50)

      # Статистика
      @stats = {
        total: Notification.count,
        pending: Notification.pending.count,
        sent: Notification.sent.count,
        failed: Notification.failed.count,
        by_type: Notification.group(:notification_type).count,
        by_channel: Notification.group(:channel).count
      }

      @users = User.where(id: Notification.distinct.pluck(:user_id)).order(:email)
    end

    def show
      @notification = Notification.find(params[:id])
    end
  end
end
