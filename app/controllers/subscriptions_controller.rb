# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!

  def index
    @current_subscription = current_user.subscription
    @plans = Subscription::PLAN_LIMITS
    @prices = Subscription::PLAN_PRICES
  end

  def upgrade
    plan = params[:plan].to_sym

    unless Subscription::PLAN_PRICES.key?(plan)
      redirect_to subscriptions_path, alert: 'Неверный тарифный план'
      return
    end

    if plan == :free
      if current_user.subscription.plan == 'free'
        redirect_to subscriptions_path, alert: 'Вы уже на бесплатном тарифе'
      else
        # Позволяем downgrade на бесплатный план
        redirect_to action: :downgrade
      end
      return
    end

    # Проверяем настройки Robokassa
    unless robokassa_configured?
      redirect_to subscriptions_path, alert: 'Платежная система не настроена. Обратитесь к администратору.', status: :see_other
      return
    end

    # Create payment for the subscription
    begin
      @payment = current_user.payments.create!(
        subscription: current_user.subscription,
        amount: Subscription::PLAN_PRICES[plan],
        provider: 'robokassa',
        status: :pending,
        metadata: {
          plan: plan.to_s,
          user_email: current_user.email
        }
      )

      # Redirect to Robokassa payment gateway
      payment_url = PaymentConfiguration.current.generate_payment_url(@payment)
      redirect_to payment_url, allow_other_host: true
    rescue ActiveRecord::RecordInvalid => e
      redirect_to subscriptions_path, alert: "Ошибка при создании платежа: #{e.message}", status: :see_other
    end
  end

  def downgrade
    subscription = current_user.subscription

    if subscription.plan == 'free'
      redirect_to subscriptions_path, alert: 'Вы уже на бесплатном тарифе', status: :see_other
      return
    end

    subscription.update!(
      plan: :free,
      current_period_end: Time.current
    )
    subscription.reset_usage!

    redirect_to subscriptions_path, notice: 'Вы перешли на бесплатный тариф', status: :see_other
  end

  def cancel
    current_user.subscription.update!(status: :canceled)
    redirect_to subscriptions_path, notice: 'Подписка отменена', status: :see_other
  end

  private

  def robokassa_configured?
    PaymentConfiguration.current.configured?
  end
end
