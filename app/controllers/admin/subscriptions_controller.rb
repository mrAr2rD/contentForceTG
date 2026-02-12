# frozen_string_literal: true

module Admin
  class SubscriptionsController < Admin::ApplicationController
    def index
      @subscriptions = Subscription.includes(:user)
                                   .order(created_at: :desc)
                                   .page(params[:page]).per(25)

      @subscriptions = @subscriptions.where(plan: params[:plan]) if params[:plan].present?
      @subscriptions = @subscriptions.where(status: params[:status]) if params[:status].present?
    end

    def show
      @subscription = Subscription.find(params[:id])
    end

    def edit
      @subscription = Subscription.find(params[:id])
    end

    def update
      @subscription = Subscription.find(params[:id])

      if @subscription.update(subscription_params)
        redirect_to admin_subscription_path(@subscription), notice: "Подписка обновлена"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @subscription = Subscription.find(params[:id])
      @subscription.destroy
      redirect_to admin_subscriptions_path, notice: "Подписка удалена", status: :see_other
    end

    private

    def subscription_params
      # Админ может изменять критичные поля подписки
      # но только если это действительно админ (проверяется в Admin::ApplicationController)
      params.require(:subscription).permit(:plan, :status, :current_period_end)
    end
  end
end
