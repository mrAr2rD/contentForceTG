# frozen_string_literal: true

module Projects
  class StyleSettingsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_project

    layout "dashboard"

    def show
      @style_samples = @project.style_samples.order(created_at: :desc)
      @style_documents = @project.style_documents.order(created_at: :desc)
      @telegram_sessions = current_user.telegram_sessions.authorized
      @telegram_bots = @project.telegram_bots.verified
    end

    def update
      if @project.update(style_settings_params)
        redirect_to project_style_settings_path(@project), notice: "Настройки стиля обновлены"
      else
        @style_samples = @project.style_samples.order(created_at: :desc)
        @style_documents = @project.style_documents.order(created_at: :desc)
        render :show, status: :unprocessable_entity
      end
    end

    def analyze
      unless @project.can_analyze_style?
        redirect_to project_style_settings_path(@project), alert: "Недостаточно данных для анализа стиля"
        return
      end

      # Устанавливаем статус "анализируется" сразу для UI
      @project.update!(style_analysis_status: :style_analyzing)

      AnalyzeStyleJob.perform_later(@project.id)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "style_status",
            partial: "projects/style_settings/status",
            locals: { project: @project }
          )
        end
        format.html { redirect_to project_style_settings_path(@project), notice: "Анализ стиля запущен" }
      end
    end

    def reset
      @project.reset_style!
      @project.style_samples.destroy_all
      @project.style_documents.destroy_all

      redirect_to project_style_settings_path(@project), notice: "Стиль сброшен"
    end

    private

    def set_project
      @project = current_user.projects.find(params[:project_id])
    end

    def style_settings_params
      params.require(:project).permit(:custom_style_enabled)
    end
  end
end
