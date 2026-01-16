# frozen_string_literal: true

class CalendarController < ApplicationController
  before_action :authenticate_user!
  layout "dashboard"

  def index
    @projects = current_user.projects.active
    @selected_project = if params[:project_id].present?
                          current_user.projects.find(params[:project_id])
                        else
                          @projects.first
                        end

    # Get posts for calendar view
    @posts = if @selected_project
               @selected_project.posts
                               .where("scheduled_at IS NOT NULL OR published_at IS NOT NULL")
                               .order(:scheduled_at, :published_at)
             else
               Post.none
             end

    # Group posts by month for calendar view
    @posts_by_date = @posts.group_by do |post|
      (post.scheduled_at || post.published_at)&.to_date
    end

    # Get upcoming scheduled posts
    @upcoming_posts = @posts.where(status: :scheduled)
                            .where("scheduled_at >= ?", Time.current)
                            .order(scheduled_at: :asc)
                            .limit(10)

    # Calendar data for JS
    @calendar_events = @posts.map do |post|
      {
        id: post.id,
        title: post.title,
        start: (post.scheduled_at || post.published_at)&.iso8601,
        status: post.status,
        url: post_path(post),
        color: post_status_color(post.status),
        telegram_bot: post.telegram_bot&.channel_name
      }
    end
  end

  private

  def post_status_color(status)
    case status
    when "published"
      "#10b981" # green
    when "scheduled"
      "#3b82f6" # blue
    when "draft"
      "#6b7280" # gray
    when "failed"
      "#ef4444" # red
    else
      "#6b7280"
    end
  end
end
