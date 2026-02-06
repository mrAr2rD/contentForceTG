# frozen_string_literal: true

module Admin
  class PlansController < Admin::ApplicationController
    before_action :check_table_exists
    before_action :set_plan, only: [:show, :edit, :update, :destroy]

    def index
      @plans = Plan.ordered
    end

    def show; end

    def new
      @plan = Plan.new
    end

    def create
      @plan = Plan.new(plan_params)

      if @plan.save
        redirect_to admin_plans_path, notice: 'План успешно создан'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @plan.update(plan_params)
        redirect_to admin_plans_path, notice: 'План успешно обновлён'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @plan.subscriptions.exists?
        redirect_to admin_plans_path, alert: 'Невозможно удалить план с активными подписками'
      else
        @plan.destroy
        redirect_to admin_plans_path, notice: 'План удалён'
      end
    end

    private

    def set_plan
      @plan = Plan.find(params[:id])
    end

    def plan_params
      params.require(:plan).permit(
        :slug, :name, :price, :position, :active,
        limits: [:projects, :bots, :posts_per_month, :ai_generations_per_month, :ai_image_generations_per_month],
        features: [:analytics, :priority_support]
      )
    end

    def check_table_exists
      return if Plan.table_exists?

      redirect_to admin_root_path,
                  alert: 'Таблица plans не существует. Выполните миграции: bin/rails db:migrate'
    end
  end
end
