# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [:show, :edit, :update, :destroy, :publish, :schedule, :remove_image]
  before_action :set_project, only: [:new, :create]
  layout "dashboard", except: [:editor]

  def index
    @posts = policy_scope(Post).includes(:project, :telegram_bot).order(created_at: :desc)
    
    # Filtering
    @posts = @posts.where(status: params[:status]) if params[:status].present?
    @posts = @posts.where(project_id: params[:project_id]) if params[:project_id].present?
  end

  def show
    authorize @post if @post
  end

  def new
    @post = @project ? @project.posts.build(user: current_user) : current_user.posts.build
    authorize @post
  end

  def create
    @post = current_user.posts.build(post_params)
    @post.project = @project if @project
    authorize @post

    if @post.save
      redirect_to editor_posts_path(post_id: @post.id), notice: 'Пост успешно создан!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @post
    @project = @post.project
  end

  def update
    authorize @post

    if @post.update(post_params)
      redirect_to @post, notice: 'Пост обновлен!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @post
    project = @post.project
    @post.destroy
    
    redirect_path = project ? project_path(project) : posts_path
    redirect_to redirect_path, notice: 'Пост удален!', status: :see_other
  end

  def publish
    authorize @post

    if @post.telegram_bot.present?
      begin
        result = @post.publish!
        redirect_to @post, notice: 'Пост опубликован!'
      rescue StandardError => e
        redirect_to @post, alert: "Ошибка публикации: #{e.message}"
      end
    else
      redirect_to @post, alert: 'Выберите Telegram бота для публикации'
    end
  end

  def schedule
    authorize @post
    scheduled_at = params[:scheduled_at]

    if scheduled_at.present?
      @post.schedule!(Time.zone.parse(scheduled_at))
      redirect_to @post, notice: "Пост запланирован на #{scheduled_at}"
    else
      redirect_to @post, alert: 'Укажите дату и время публикации'
    end
  rescue StandardError => e
    redirect_to @post, alert: "Ошибка планирования: #{e.message}"
  end

  def remove_image
    authorize @post, :update?

    if @post.image.attached?
      @post.image.purge
      # Если тип поста требует картинку, меняем на текстовый
      @post.update!(post_type: :text) if @post.image? || @post.image_button?
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: @post, notice: 'Изображение удалено' }
      format.json { render json: { success: true } }
    end
  end

  # Editor view - трехпанельный интерфейс
  def editor
    # Check for post_id parameter (when redirected from create)
    if params[:post_id].present?
      @post = current_user.posts.find(params[:post_id])
      authorize @post, :edit?
    else
      @post = current_user.posts.build
      authorize @post, :new?
    end

    @project = @post.project || current_user.projects.first
    @telegram_bots = @project&.telegram_bots&.verified || []

    render layout: "editor"
  end

  private

  def set_post
    @post = current_user.posts.find(params[:id])
  end

  def set_project
    @project = current_user.projects.find(params[:project_id]) if params[:project_id].present?
  end

  def post_params
    permitted = params.require(:post).permit(
      :title, :content, :status, :project_id, :telegram_bot_id,
      :published_at, :telegram_message_id, :image,
      :post_type, :button_text, :button_url
    )

    # Convert empty strings to nil for optional foreign keys
    permitted[:project_id] = nil if permitted[:project_id].blank?
    permitted[:telegram_bot_id] = nil if permitted[:telegram_bot_id].blank?

    permitted
  end
end
