# frozen_string_literal: true

module Admin
  class AiModelsController < Admin::ApplicationController
    before_action :set_ai_model, only: [:edit, :update, :toggle_active]

    def index
      @ai_models = AiModel.order(:tier, :name)
      @grouped_models = @ai_models.group_by(&:tier)
    end

    def edit; end

    def update
      if @ai_model.update(ai_model_params)
        redirect_to admin_ai_models_path, notice: 'Модель обновлена'
      else
        render :edit, status: :unprocessable_entity
      end
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
        :name, :provider, :tier, :active,
        :input_cost_per_1k, :output_cost_per_1k, :max_tokens
      )
    end
  end
end
