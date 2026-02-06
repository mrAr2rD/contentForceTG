# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy, :archive, :activate]
  layout "dashboard"

  def index
    @projects = policy_scope(Project).order(updated_at: :desc)
  end

  def show
    authorize @project
    @telegram_bots = @project.telegram_bots.order(created_at: :desc)
    @recent_posts = @project.posts.includes(:user, :telegram_bot).order(created_at: :desc).limit(10)
  end

  def new
    @project = current_user.projects.build
    authorize @project
  end

  def create
    @project = current_user.projects.build(project_params)
    authorize @project

    if @project.save
      redirect_to @project, notice: 'Проект успешно создан!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @project
  end

  def update
    authorize @project

    if @project.update(project_params)
      redirect_to @project, notice: 'Проект обновлен!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @project
    @project.destroy
    redirect_to projects_path, notice: 'Проект удален!', status: :see_other
  end

  def archive
    authorize @project
    @project.archive!
    redirect_to projects_path, notice: 'Проект архивирован!'
  end

  def activate
    authorize @project
    @project.activate!
    redirect_to projects_path, notice: 'Проект активирован!'
  end

  private

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(
      :name,
      :description,
      :status,
      :ai_model,
      :ai_temperature,
      :system_prompt,
      :writing_style
    )
  end
end
