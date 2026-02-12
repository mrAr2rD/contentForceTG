# frozen_string_literal: true

module Admin
  class ProjectsController < Admin::ApplicationController
    def index
      @projects = Project.includes(:user)
                        .order(created_at: :desc)
                        .page(params[:page]).per(25)

      @projects = @projects.where(user_id: params[:user_id]) if params[:user_id].present?
    end

    def show
      @project = Project.find(params[:id])
    end

    def destroy
      @project = Project.find(params[:id])
      @project.destroy
      redirect_to admin_projects_path, notice: "Проект удален", status: :see_other
    end
  end
end
