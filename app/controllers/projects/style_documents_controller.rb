# frozen_string_literal: true

module Projects
  class StyleDocumentsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_project
    before_action :set_style_document, only: [:destroy, :toggle]

    def index
      @style_documents = @project.style_documents.order(created_at: :desc)

      respond_to do |format|
        format.html { redirect_to project_style_settings_path(@project) }
        format.json { render json: @style_documents }
      end
    end

    def create
      file = params[:file]

      unless file.present?
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "upload_status",
              partial: "projects/style_documents/upload_status",
              locals: { error: "Выберите файл" }
            )
          end
          format.html { redirect_to project_style_settings_path(@project), alert: "Выберите файл" }
        end
        return
      end

      # Проверка типа файла
      allowed_extensions = %w[.txt .md .markdown]
      extension = File.extname(file.original_filename).downcase

      unless allowed_extensions.include?(extension)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "upload_status",
              partial: "projects/style_documents/upload_status",
              locals: { error: "Разрешены только .txt и .md файлы" }
            )
          end
          format.html { redirect_to project_style_settings_path(@project), alert: "Неверный формат файла" }
        end
        return
      end

      # Проверка размера
      if file.size > StyleDocument::MAX_FILE_SIZE
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "upload_status",
              partial: "projects/style_documents/upload_status",
              locals: { error: "Файл слишком большой (макс. 1 MB)" }
            )
          end
          format.html { redirect_to project_style_settings_path(@project), alert: "Файл слишком большой" }
        end
        return
      end

      content = file.read.force_encoding("UTF-8")

      @style_document = @project.style_documents.build(
        filename: file.original_filename,
        content: content,
        content_type: file.content_type,
        file_size: file.size
      )

      if @style_document.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.prepend("style_documents_list", partial: "projects/style_documents/document", locals: { document: @style_document }),
              turbo_stream.replace("upload_status", partial: "projects/style_documents/upload_status", locals: { success: true }),
              turbo_stream.replace("style_stats", partial: "projects/style_settings/stats", locals: { project: @project.reload })
            ]
          end
          format.html { redirect_to project_style_settings_path(@project), notice: "Документ загружен" }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "upload_status",
              partial: "projects/style_documents/upload_status",
              locals: { error: @style_document.errors.full_messages.join(", ") }
            )
          end
          format.html { redirect_to project_style_settings_path(@project), alert: @style_document.errors.full_messages.join(", ") }
        end
      end
    end

    def destroy
      @style_document.destroy

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("document_#{@style_document.id}"),
            turbo_stream.replace("style_stats", partial: "projects/style_settings/stats", locals: { project: @project.reload })
          ]
        end
        format.html { redirect_to project_style_settings_path(@project), notice: "Документ удалён" }
      end
    end

    def toggle
      @style_document.update!(used_for_analysis: !@style_document.used_for_analysis)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("document_#{@style_document.id}", partial: "projects/style_documents/document", locals: { document: @style_document }),
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

    def set_style_document
      @style_document = @project.style_documents.find(params[:id])
    end
  end
end
