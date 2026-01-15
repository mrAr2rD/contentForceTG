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
    end
  end
end
