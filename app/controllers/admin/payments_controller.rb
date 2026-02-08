# frozen_string_literal: true

module Admin
  class PaymentsController < Admin::ApplicationController
    before_action :set_payment, only: [:show, :refund]

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
        redirect_to admin_payment_path(@payment), notice: 'Платёж отмечен как возвращённый'
      else
        redirect_to admin_payment_path(@payment), alert: 'Невозможно вернуть платёж (только завершённые платежи могут быть возвращены)'
      end
    end

    private

    def set_payment
      @payment = Payment.find(params[:id])
    end
  end
end
