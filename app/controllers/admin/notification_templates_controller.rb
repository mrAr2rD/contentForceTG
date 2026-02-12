# frozen_string_literal: true

module Admin
  class NotificationTemplatesController < Admin::ApplicationController
    before_action :check_table_exists
    before_action :set_template, only: [ :show, :edit, :update, :destroy ]

    def index
      @templates = NotificationTemplate.order(:event_type, :channel)
      @grouped_templates = @templates.group_by(&:event_type)
    end

    def show; end

    def new
      @template = NotificationTemplate.new
    end

    def create
      @template = NotificationTemplate.new(template_params)

      if @template.save
        redirect_to admin_notification_templates_path, notice: "Шаблон создан"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @template.update(template_params)
        redirect_to admin_notification_templates_path, notice: "Шаблон обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @template.destroy
      redirect_to admin_notification_templates_path, notice: "Шаблон удалён"
    end

    # Загрузить дефолтные шаблоны
    def load_defaults
      NotificationTemplate::DEFAULTS.each do |event_type, channels|
        channels.each do |channel, attrs|
          template = NotificationTemplate.find_or_initialize_by(
            event_type: event_type.to_s,
            channel: channel.to_s
          )

          if template.new_record?
            template.assign_attributes(
              subject: attrs[:subject],
              body_template: attrs[:body],
              active: true
            )
            template.save!
          end
        end
      end

      redirect_to admin_notification_templates_path, notice: "Дефолтные шаблоны загружены"
    end

    private

    def set_template
      @template = NotificationTemplate.find(params[:id])
    end

    def template_params
      params.require(:notification_template).permit(
        :event_type, :channel, :subject, :body_template, :active
      )
    end

    def check_table_exists
      return if NotificationTemplate.table_exists?

      redirect_to admin_root_path,
                  alert: "Таблица notification_templates не существует. Выполните миграции: bin/rails db:migrate"
    end
  end
end
