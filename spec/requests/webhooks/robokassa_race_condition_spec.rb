# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Robokassa Webhook Race Condition Protection", type: :request do
  let(:user) { create(:user) }
  let(:subscription) { create(:subscription, user: user, status: :inactive) }
  let!(:payment) do
    create(:payment,
           user: user,
           subscription: subscription,
           status: :pending,
           amount: 590.0,
           provider: "robokassa",
           invoice_number: 123456,
           metadata: { "plan" => "starter" })
  end
  let!(:plan) { create(:plan, slug: "starter", name: "Starter") }

  let(:config) do
    PaymentConfiguration.create!(
      merchant_login: "test_merchant",
      password_1: "password1",
      password_2: "password2",
      test_mode: true,
      enabled: true
    )
  end

  before do
    # Настраиваем конфигурацию
    allow(PaymentConfiguration).to receive(:current).and_return(config)

    # Мокаем валидацию подписи
    allow(config).to receive(:valid_result_signature?).and_return(true)
  end

  describe "POST /webhooks/robokassa/result" do
    let(:valid_params) do
      {
        OutSum: "590.00",
        InvId: payment.invoice_number,
        SignatureValue: "valid_signature"
      }
    end

    describe "SECURITY: idempotency and race condition protection" do
      it "successfully processes payment on first webhook" do
        expect {
          post "/webhooks/robokassa/result", params: valid_params
        }.to change { payment.reload.status }.from("pending").to("completed")

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("OK#{payment.invoice_number}")

        subscription.reload
        expect(subscription.status).to eq("active")
        expect(subscription.plan).to eq("starter")
      end

      it "handles duplicate webhook gracefully (idempotency)" do
        # Первый webhook
        post "/webhooks/robokassa/result", params: valid_params
        expect(response).to have_http_status(:ok)

        payment.reload
        subscription.reload

        # Сохраняем данные первого webhook
        first_period_start = subscription.current_period_start
        first_period_end = subscription.current_period_end
        first_paid_at = payment.paid_at

        # Второй webhook (дубликат)
        post "/webhooks/robokassa/result", params: valid_params

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("OK")

        payment.reload
        subscription.reload

        # Данные НЕ должны измениться
        expect(payment.status).to eq("completed")
        expect(subscription.status).to eq("active")
        expect(subscription.current_period_start).to eq(first_period_start)
        expect(subscription.current_period_end).to eq(first_period_end)
        expect(payment.paid_at).to eq(first_paid_at)
      end

      it "uses pessimistic locking to prevent concurrent modifications" do
        # Симулируем concurrent requests
        threads = []
        results = []

        # Запускаем 3 одновременных запроса
        3.times do
          threads << Thread.new do
            post "/webhooks/robokassa/result", params: valid_params
            results << {
              status: response.status,
              body: response.body
            }
          end
        end

        threads.each(&:join)

        # Все запросы должны вернуть 200
        expect(results.all? { |r| r[:status] == 200 }).to be true

        # Но подписка должна быть активирована только один раз
        payment.reload
        subscription.reload

        expect(payment.status).to eq("completed")
        expect(subscription.status).to eq("active")
        expect(payment.paid_at).to be_present
      end

      it "rejects webhook if payment already completed (different timing)" do
        # Вручную завершаем платёж
        payment.with_lock do
          payment.mark_as_completed!
        end

        # Пытаемся обработать webhook
        post "/webhooks/robokassa/result", params: valid_params

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("already completed")
      end

      it "rejects webhook if payment in invalid status" do
        payment.update!(status: :refunded)

        post "/webhooks/robokassa/result", params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid payment status")
      end
    end

    describe "SECURITY: signature validation" do
      it "rejects webhook with invalid signature" do
        allow(config).to receive(:valid_result_signature?).and_return(false)

        expect {
          post "/webhooks/robokassa/result", params: valid_params
        }.not_to change { payment.reload.status }

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid signature")
      end
    end

    describe "error handling" do
      it "handles missing payment gracefully" do
        post "/webhooks/robokassa/result", params: {
          OutSum: "590.00",
          InvId: 999999,  # Несуществующий payment
          SignatureValue: "valid"
        }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("Payment not found")
      end

      it "handles missing plan gracefully" do
        payment.update!(metadata: { "plan" => "nonexistent_plan" })

        expect {
          post "/webhooks/robokassa/result", params: valid_params
        }.not_to raise_error

        # Должен обработать без ошибки, просто plan_record будет nil
      end
    end
  end

  describe "POST /webhooks/robokassa/fail" do
    it "marks payment as failed with locking" do
      payment.update!(status: :pending)

      post "/webhooks/robokassa/fail", params: { InvId: payment.invoice_number }

      payment.reload
      expect(payment.status).to eq("failed")
      expect(response).to redirect_to(subscriptions_path)
    end

    it "does not mark completed payment as failed" do
      payment.with_lock { payment.mark_as_completed! }

      post "/webhooks/robokassa/fail", params: { InvId: payment.invoice_number }

      payment.reload
      expect(payment.status).to eq("completed")
    end

    it "handles concurrent fail requests" do
      payment.update!(status: :pending)

      threads = []
      3.times do
        threads << Thread.new do
          post "/webhooks/robokassa/fail", params: { InvId: payment.invoice_number }
        end
      end

      threads.each(&:join)

      payment.reload
      expect(payment.status).to eq("failed")
    end
  end

  describe "Payment model methods" do
    describe "#mark_as_completed!" do
      it "is idempotent" do
        payment.mark_as_completed!
        first_paid_at = payment.paid_at

        # Повторный вызов не должен изменить данные
        payment.mark_as_completed!

        expect(payment.paid_at).to eq(first_paid_at)
      end
    end

    describe "#mark_as_failed!" do
      it "does not change completed payment to failed" do
        payment.mark_as_completed!

        result = payment.mark_as_failed!

        expect(result).to be false
        expect(payment.status).to eq("completed")
      end

      it "marks pending payment as failed" do
        payment.update!(status: :pending)

        result = payment.mark_as_failed!

        expect(result).not_to be false
        expect(payment.status).to eq("failed")
      end
    end
  end
end
