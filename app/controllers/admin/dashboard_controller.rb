# frozen_string_literal: true

module Admin
  class DashboardController < Admin::ApplicationController
    def index
      @users_count = User.count
      @projects_count = Project.count
      @posts_count = Post.count
      @telegram_bots_count = TelegramBot.count
      @subscriptions_count = Subscription.count

      @recent_users = User.order(created_at: :desc).limit(5)
      @recent_posts = Post.order(created_at: :desc).limit(5)

      # ROI данные за последние 30 дней
      @roi_calculator = Analytics::RoiCalculatorService.new(period: 30.days)
      @roi_summary = @roi_calculator.calculate
    end
  end
end
