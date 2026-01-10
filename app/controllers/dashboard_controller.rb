class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @recent_projects = current_user.projects.order(updated_at: :desc).limit(5) rescue []
    @recent_posts = current_user.posts.order(created_at: :desc).limit(5) rescue []
  end
end
