# frozen_string_literal: true

module Webhooks
  class RobokassaController < ApplicationController
    skip_before_action :verify_authenticity_token

    # Result URL - called after successful payment
    def result
      # Логируем входящий запрос для отладки
      Rails.logger.info("Robokassa Result URL called with params: #{params.inspect}")

      config = PaymentConfiguration.current

      # Проверка подписи
      unless config.valid_result_signature?(params[:OutSum], params[:InvId], params[:SignatureValue])
        Rails.logger.error("Robokassa signature validation failed. OutSum: #{params[:OutSum]}, InvId: #{params[:InvId]}, Signature: #{params[:SignatureValue]}")
        render json: { error: 'Invalid signature' }, status: :forbidden
        return
      end

      payment_id = params[:InvId]
      payment = Payment.find_by(invoice_number: payment_id)

      unless payment
        Rails.logger.error("Payment not found for InvId: #{payment_id}")
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
          plan_slug = payment.metadata['plan']
          plan_record = Plan.cached_find_by_slug(plan_slug) || Plan.find_by_slug(plan_slug)
          subscription = payment.subscription

          Rails.logger.info("Activating subscription for user #{subscription.user.email}: plan=#{plan_slug}")

          subscription.update!(
            plan: plan_slug,
            plan_record: plan_record,
            status: :active,
            current_period_start: Time.current,
            current_period_end: 1.month.from_now
          )

          # Reset usage counters
          subscription.reset_usage!

          Rails.logger.info("Payment #{payment_id} processed successfully")
        end

        render plain: "OK#{payment_id}", status: :ok
      rescue StandardError => e
        Rails.logger.error("Robokassa payment processing failed: #{e.message}")
        Rails.logger.error(e.backtrace.first(10).join("\n"))
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
