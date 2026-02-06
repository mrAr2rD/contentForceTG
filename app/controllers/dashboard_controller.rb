class DashboardController < ApplicationController
  before_action :authenticate_user!
  layout "dashboard"

  def index
    @user = current_user
    @recent_projects = current_user.projects.order(updated_at: :desc).limit(5)
    @recent_posts = current_user.posts.includes(:project, :telegram_bot).order(created_at: :desc).limit(5)
  end
end
