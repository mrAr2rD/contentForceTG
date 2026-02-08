# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :ensure_subscription

  def index
    @current_subscription = current_user.subscription
    @plans = Plan.cached_all
  end

  def upgrade
    plan_slug = params[:plan].to_s
    @plan = Plan.cached_find_by_slug(plan_slug)

    unless @plan&.active?
      redirect_to subscriptions_path, alert: "Неверный тарифный план"
      return
    end

    if @plan.free?
      if current_user.subscription.plan == "free"
        redirect_to subscriptions_path, alert: "Вы уже на бесплатном тарифе"
      else
        redirect_to action: :downgrade
      end
      return
    end

    # Проверяем настройки Robokassa
    unless robokassa_configured?
      redirect_to subscriptions_path, alert: "Платежная система не настроена. Обратитесь к администратору.", status: :see_other
      return
    end

    # Create payment for the subscription
    begin
      @payment = current_user.payments.create!(
        subscription: current_user.subscription,
        amount: @plan.price,
        provider: "robokassa",
        status: :pending,
        metadata: {
          plan: @plan.slug,
          plan_id: @plan.id,
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

    if subscription.plan == "free"
      redirect_to subscriptions_path, alert: "Вы уже на бесплатном тарифе", status: :see_other
      return
    end

    free_plan = Plan.cached_find_by_slug(:free)
    subscription.update!(
      plan: :free,
      plan_record: free_plan,
      current_period_end: Time.current
    )
    subscription.reset_usage!

    redirect_to subscriptions_path, notice: "Вы перешли на бесплатный тариф", status: :see_other
  end

  def cancel
    current_user.subscription.update!(status: :canceled)
    redirect_to subscriptions_path, notice: "Подписка отменена", status: :see_other
  end

  private

  # Гарантируем наличие подписки для старых пользователей
  def ensure_subscription
    return if current_user.subscription.present?

    current_user.create_subscription!(plan: :free, status: :active)
  end

  def robokassa_configured?
    PaymentConfiguration.current.configured?
  end
end
