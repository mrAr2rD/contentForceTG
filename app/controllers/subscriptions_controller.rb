# frozen_string_literal: true

class SubscriptionsController < ApplicationController
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
      redirect_to subscriptions_path, alert: 'Вы уже на бесплатном тарифе'
      return
    end

    # Create payment for the subscription
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
    redirect_to robokassa_payment_url(@payment), allow_other_host: true
  end

  def downgrade
    current_user.subscription.update!(plan: :free)
    redirect_to subscriptions_path, notice: 'Вы перешли на бесплатный тариф'
  end

  def cancel
    current_user.subscription.update!(status: :canceled)
    redirect_to subscriptions_path, notice: 'Подписка отменена'
  end

  private

  def robokassa_payment_url(payment)
    # Robokassa payment URL generation
    # This will be implemented in Robokassa service
    merchant_login = ENV['ROBOKASSA_MERCHANT_LOGIN']
    password1 = ENV['ROBOKASSA_PASSWORD_1']

    plan = payment.metadata['plan']
    amount = payment.amount.to_f
    inv_id = payment.invoice_number
    description = "Подписка ContentForce - #{plan.titleize}"

    # Generate signature: MD5(MerchantLogin:OutSum:InvId:Password#1)
    signature_string = "#{merchant_login}:#{amount}:#{inv_id}:#{password1}"
    signature = Digest::MD5.hexdigest(signature_string)

    # Build payment URL
    params = {
      MerchantLogin: merchant_login,
      OutSum: amount,
      InvId: inv_id,
      Description: description,
      SignatureValue: signature,
      IsTest: Rails.env.production? ? 0 : 1
    }

    "https://auth.robokassa.ru/Merchant/Index.aspx?#{params.to_query}"
  end
end
