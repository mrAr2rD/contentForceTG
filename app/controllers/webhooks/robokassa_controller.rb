# frozen_string_literal: true

module Webhooks
  class RobokassaController < ApplicationController
    skip_before_action :verify_authenticity_token

    # Result URL - called after successful payment
    def result
      config = PaymentConfiguration.current
      unless config.valid_result_signature?(params[:OutSum], params[:InvId], params[:SignatureValue])
        render json: { error: 'Invalid signature' }, status: :forbidden
        return
      end

      payment_id = params[:InvId]
      payment = Payment.find_by(invoice_number: payment_id)

      unless payment
        render json: { error: 'Payment not found' }, status: :not_found
        return
      end

      # Обновляем платёж и подписку в транзакции для целостности данных
      begin
        ActiveRecord::Base.transaction do
          # Update payment status
          payment.mark_as_completed!
          payment.update!(provider_payment_id: "robokassa_#{params[:InvId]}_#{Time.current.to_i}")

          # Upgrade user subscription
          plan = payment.metadata['plan'].to_sym
          subscription = payment.subscription

          subscription.update!(
            plan: plan,
            status: :active,
            current_period_start: Time.current,
            current_period_end: 1.month.from_now
          )

          # Reset usage counters
          subscription.reset_usage!
        end

        render plain: "OK#{payment_id}", status: :ok
      rescue StandardError => e
        Rails.logger.error("Robokassa payment processing failed: #{e.message}")
        Rails.logger.error(e.backtrace.first(5).join("\n"))
        render json: { error: 'Payment processing failed' }, status: :internal_server_error
      end
    end

    # Success URL - redirect user here after payment
    def success
      @payment = Payment.find_by(invoice_number: params[:InvId])

      if @payment&.completed?
        redirect_to subscriptions_path, notice: 'Оплата прошла успешно! Ваша подписка активирована.'
      else
        redirect_to subscriptions_path, alert: 'Ошибка при обработке платежа. Обратитесь в поддержку.'
      end
    end

    # Fail URL - redirect user here if payment failed
    def fail
      payment = Payment.find_by(invoice_number: params[:InvId])
      payment&.mark_as_failed!

      redirect_to subscriptions_path, alert: 'Оплата не прошла. Попробуйте еще раз.'
    end

  end
end
