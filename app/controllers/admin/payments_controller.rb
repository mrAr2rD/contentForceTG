# frozen_string_literal: true

module Admin
  class PaymentsController < Admin::ApplicationController
    def index
      @payments = Payment.includes(:user, :subscription)
                        .order(created_at: :desc)
                        .page(params[:page])
                        .per(50)

      # Filter by status if provided
      @payments = @payments.where(status: params[:status]) if params[:status].present?
    end

    def show
      @payment = Payment.find(params[:id])
    end
  end
end
