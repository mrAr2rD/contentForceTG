# frozen_string_literal: true

module Admin
  class PaymentsController < Admin::ApplicationController
    before_action :set_payment, only: [ :show, :refund, :confirm, :cancel ]

    def index
      @payments = Payment.includes(:user, :subscription)
                        .order(created_at: :desc)
                        .page(params[:page])
                        .per(50)

      # Filter by status if provided
      @payments = @payments.where(status: params[:status]) if params[:status].present?

      @stats = {
        total: Payment.count,
        completed: Payment.completed.count,
        pending: Payment.pending.count,
        refunded: Payment.refunded.count,
        total_amount: Payment.completed.sum(:amount)
      }
    end

    def show; end

    def refund
      if @payment.refund!
        redirect_to admin_payment_path(@payment), notice: "Платёж отмечен как возвращённый"
      else
        redirect_to admin_payment_path(@payment), alert: "Невозможно вернуть платёж (только завершённые платежи могут быть возвращены)"
      end
    end

    # Ручное подтверждение платежа и активация подписки
    def confirm
      unless @payment.pending? || @payment.failed?
        redirect_to admin_payment_path(@payment), alert: "Можно подтверждать только pending или failed платежи"
        return
      end

      begin
        ActiveRecord::Base.transaction do
          # Обновляем платёж
          @payment.mark_as_completed!
          @payment.update!(provider_payment_id: "manual_confirm_#{Time.current.to_i}")

          # Активируем подписку
          plan_slug = @payment.metadata["plan"]
          plan_record = Plan.cached_find_by_slug(plan_slug) || Plan.find_by_slug(plan_slug)
          subscription = @payment.subscription

          subscription.update!(
            plan: plan_slug,
            plan_record: plan_record,
            status: :active,
            current_period_start: Time.current,
            current_period_end: 1.month.from_now
          )

          # Сбрасываем счётчики
          subscription.reset_usage!
        end

        redirect_to admin_payment_path(@payment), notice: "Платёж подтверждён, подписка активирована"
      rescue StandardError => e
        redirect_to admin_payment_path(@payment), alert: "Ошибка при подтверждении: #{e.message}"
      end
    end

    # Отмена платежа
    def cancel
      if @payment.completed? || @payment.refunded?
        redirect_to admin_payment_path(@payment), alert: "Нельзя отменить завершённые или возвращённые платежи"
        return
      end

      @payment.update!(status: :canceled)
      redirect_to admin_payment_path(@payment), notice: "Платёж отменён"
    end

    private

    def set_payment
      @payment = Payment.find(params[:id])
    end
  end
end
