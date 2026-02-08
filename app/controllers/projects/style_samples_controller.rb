# frozen_string_literal: true

module Projects
  class StyleSamplesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_project
    before_action :set_style_sample, only: [:destroy, :toggle]

    def index
      @style_samples = @project.style_samples.order(created_at: :desc)

      respond_to do |format|
        format.html { redirect_to project_style_settings_path(@project) }
        format.json { render json: @style_samples }
      end
    end

    def create
      @style_sample = @project.style_samples.build(style_sample_params)
      @style_sample.source_type = "manual"

      if @style_sample.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.prepend("style_samples_list", partial: "projects/style_samples/sample", locals: { sample: @style_sample }),
              turbo_stream.replace("new_sample_form", partial: "projects/style_samples/form", locals: { project: @project }),
              turbo_stream.replace("style_stats", partial: "projects/style_settings/stats", locals: { project: @project.reload })
            ]
          end
          format.html { redirect_to project_style_settings_path(@project), notice: "Пример добавлен" }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "new_sample_form",
              partial: "projects/style_samples/form",
              locals: { project: @project, sample: @style_sample }
            )
          end
          format.html { redirect_to project_style_settings_path(@project), alert: @style_sample.errors.full_messages.join(", ") }
        end
      end
    end

    def import_from_telegram
      telegram_session = current_user.telegram_sessions.authorized.find(params[:telegram_session_id])
      channel_username = params[:channel_username]
      limit = (params[:limit] || 100).to_i.clamp(10, 1000)

      ImportStyleSamplesJob.perform_later(
        project_id: @project.id,
        telegram_session_id: telegram_session.id,
        channel_username: channel_username,
        limit: limit
      )

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "import_status",
            partial: "projects/style_samples/import_status",
            locals: { status: :started, channel: channel_username, limit: limit }
          )
        end
        format.html { redirect_to project_style_settings_path(@project), notice: "Импорт запущен" }
      end
    end

    def destroy
      @style_sample.destroy

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("sample_#{@style_sample.id}"),
            turbo_stream.replace("style_stats", partial: "projects/style_settings/stats", locals: { project: @project.reload })
          ]
        end
        format.html { redirect_to project_style_settings_path(@project), notice: "Пример удалён" }
      end
    end

    def toggle
      @style_sample.update!(used_for_analysis: !@style_sample.used_for_analysis)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("sample_#{@style_sample.id}", partial: "projects/style_samples/sample", locals: { sample: @style_sample }),
            turbo_stream.replace("style_stats", partial: "projects/style_settings/stats", locals: { project: @project.reload })
          ]
        end
        format.html { redirect_to project_style_settings_path(@project) }
      end
    end

    private

    def set_project
      @project = current_user.projects.find(params[:project_id])
    end

    def set_style_sample
      @style_sample = @project.style_samples.find(params[:id])
    end

    def style_sample_params
      params.require(:style_sample).permit(:content)
    end
  end
end
