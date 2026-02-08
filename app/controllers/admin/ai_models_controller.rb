# frozen_string_literal: true

module Admin
  class AiModelsController < Admin::ApplicationController
    before_action :check_table_exists
    before_action :set_ai_model, only: [:show, :edit, :update, :destroy, :toggle_active]

    def index
      @ai_models = AiModel.order(:tier, :name)
      @grouped_models = @ai_models.group_by(&:tier)
    end

    def show; end

    def new
      @ai_model = AiModel.new
    end

    def create
      @ai_model = AiModel.new(ai_model_params)

      if @ai_model.save
        redirect_to admin_ai_models_path, notice: 'Модель создана'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @ai_model.update(ai_model_params)
        redirect_to admin_ai_models_path, notice: 'Модель обновлена'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @ai_model.destroy
      redirect_to admin_ai_models_path, notice: 'Модель удалена'
    end

    def toggle_active
      @ai_model.update!(active: !@ai_model.active)
      redirect_to admin_ai_models_path, notice: "Модель #{@ai_model.active? ? 'активирована' : 'деактивирована'}"
    end

    # Синхронизация с дефолтами
    def sync_defaults
      AiModel::DEFAULTS.each do |model_id, attrs|
        model = AiModel.find_or_initialize_by(model_id: model_id)
        model.assign_attributes(attrs) if model.new_record?
        model.save!
      end

      redirect_to admin_ai_models_path, notice: 'Модели синхронизированы с дефолтами'
    end

    private

    def set_ai_model
      @ai_model = AiModel.find(params[:id])
    end

    def ai_model_params
      params.require(:ai_model).permit(
        :model_id, :name, :provider, :tier, :active,
        :input_cost_per_1k, :output_cost_per_1k, :max_tokens
      )
    end

    def check_table_exists
      return if AiModel.table_exists?

      redirect_to admin_root_path,
                  alert: 'Таблица ai_models не существует. Выполните миграции: bin/rails db:migrate'
    end
  end
end
