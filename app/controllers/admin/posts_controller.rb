# frozen_string_literal: true

module Admin
  class PostsController < Admin::ApplicationController
    def index
      @posts = Post.includes(:user, :project, :telegram_bot)
                   .order(created_at: :desc)
                   .page(params[:page]).per(25)

      @posts = @posts.where(status: params[:status]) if params[:status].present?
      @posts = @posts.where(user_id: params[:user_id]) if params[:user_id].present?
    end

    def show
      @post = Post.find(params[:id])
    end

    def destroy
      @post = Post.find(params[:id])
      @post.destroy
      redirect_to admin_posts_path, notice: 'Пост удален', status: :see_other
    end
  end
end
