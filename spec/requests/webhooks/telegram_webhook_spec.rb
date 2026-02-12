# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Telegram Webhook Authentication', type: :request do
  let(:telegram_bot) { create(:telegram_bot, webhook_secret: 'test_secret_token_32_bytes_long!!') }
  let(:webhook_url) { "/webhooks/telegram/#{telegram_bot.bot_token}" }
  let(:valid_webhook_data) do
    {
      update_id: 123456789,
      channel_post: {
        message_id: 100,
        chat: { id: telegram_bot.channel_id, type: 'channel' },
        text: 'Test post',
        date: Time.current.to_i,
        views: 42
      }
    }
  end

  describe 'POST /webhooks/telegram/:bot_token' do
    context 'with valid secret token' do
      let(:headers) { { 'X-Telegram-Bot-Api-Secret-Token' => telegram_bot.webhook_secret } }

      it 'accepts the webhook' do
        post webhook_url, params: valid_webhook_data, headers: headers, as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'processes the webhook data' do
        expect(Rails.logger).to receive(:info).with(/Telegram webhook received/)

        post webhook_url, params: valid_webhook_data, headers: headers, as: :json
      end
    end

    context 'with invalid secret token' do
      let(:headers) { { 'X-Telegram-Bot-Api-Secret-Token' => 'wrong_secret' } }

      it 'rejects the webhook' do
        post webhook_url, params: valid_webhook_data, headers: headers, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it 'logs the failed attempt' do
        expect(Rails.logger).to receive(:error).with(/Webhook: Invalid secret/)

        post webhook_url, params: valid_webhook_data, headers: headers, as: :json
      end

      it 'does not process the webhook data' do
        expect_any_instance_of(Webhooks::TelegramController).not_to receive(:process_channel_post)

        post webhook_url, params: valid_webhook_data, headers: headers, as: :json
      end
    end

    context 'without secret token header' do
      it 'rejects the webhook' do
        post webhook_url, params: valid_webhook_data, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with non-existent bot token' do
      let(:invalid_webhook_url) { '/webhooks/telegram/invalid_bot_token_123' }
      let(:headers) { { 'X-Telegram-Bot-Api-Secret-Token' => 'any_secret' } }

      it 'returns not found' do
        post invalid_webhook_url, params: valid_webhook_data, headers: headers, as: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'logs the attempt' do
        expect(Rails.logger).to receive(:warn).with(/Bot not found/)

        post invalid_webhook_url, params: valid_webhook_data, headers: headers, as: :json
      end
    end

    context 'legacy mode - bot without webhook_secret' do
      let(:legacy_bot) { create(:telegram_bot, webhook_secret: nil) }
      let(:legacy_webhook_url) { "/webhooks/telegram/#{legacy_bot.bot_token}" }
      let(:headers) { { 'X-Telegram-Bot-Api-Secret-Token' => 'any_secret' } }

      it 'allows the webhook (migration mode)' do
        post legacy_webhook_url, params: valid_webhook_data, headers: headers, as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn).with(/has no webhook secret \(migration mode\)/)

        post legacy_webhook_url, params: valid_webhook_data, headers: headers, as: :json
      end
    end

    context 'timing attack protection' do
      it 'uses secure_compare for token comparison' do
        headers = { 'X-Telegram-Bot-Api-Secret-Token' => 'wrong_secret' }

        expect(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_call_original

        post webhook_url, params: valid_webhook_data, headers: headers, as: :json
      end
    end
  end

  describe 'Security edge cases' do
    let(:headers) { { 'X-Telegram-Bot-Api-Secret-Token' => telegram_bot.webhook_secret } }

    context 'with SQL injection attempt in bot_token' do
      let(:malicious_url) { "/webhooks/telegram/123'; DROP TABLE telegram_bots;--" }

      it 'safely handles malicious input' do
        post malicious_url, params: valid_webhook_data, headers: headers, as: :json
        expect(response).to have_http_status(:not_found)

        # Verify table still exists
        expect(TelegramBot.count).to be >= 0
      end
    end

    context 'with extremely long secret token' do
      let(:headers) { { 'X-Telegram-Bot-Api-Secret-Token' => 'a' * 10000 } }

      it 'handles long tokens gracefully' do
        post webhook_url, params: valid_webhook_data, headers: headers, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with special characters in secret token' do
      let(:special_bot) { create(:telegram_bot, webhook_secret: 'test!@#$%^&*()[]{}') }
      let(:special_webhook_url) { "/webhooks/telegram/#{special_bot.bot_token}" }
      let(:headers) { { 'X-Telegram-Bot-Api-Secret-Token' => special_bot.webhook_secret } }

      it 'correctly validates special characters' do
        post special_webhook_url, params: valid_webhook_data, headers: headers, as: :json
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
