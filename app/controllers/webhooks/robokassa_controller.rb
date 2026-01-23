# frozen_string_literal: true

module Webhooks
  class RobokassaController < ApplicationController
    skip_before_action :verify_authenticity_token

    # Result URL - called after successful payment
    def result
      unless valid_signature?(params, ENV['ROBOKASSA_PASSWORD_2'])
        render json: { error: 'Invalid signature' }, status: :forbidden
        return
      end

      payment_id = params[:InvId]
      payment = Payment.find_by(invoice_number: payment_id)

      unless payment
        render json: { error: 'Payment not found' }, status: :not_found
        return
      end

      # Update payment status
      payment.mark_as_completed!
      payment.update!(provider_payment_id: params[:OutSum])

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

      render plain: "OK#{payment_id}", status: :ok
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

    private

    def valid_signature?(params, password)
      # Signature validation: MD5(OutSum:InvId:Password#2)
      out_sum = params[:OutSum]
      inv_id = params[:InvId]
      signature_string = "#{out_sum}:#{inv_id}:#{password}"
      expected_signature = Digest::MD5.hexdigest(signature_string).upcase

      params[:SignatureValue]&.upcase == expected_signature
    end
  end
end
