# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::WebhookService do
  let(:telegram_bot) { create(:telegram_bot) }
  let(:service) { described_class.new(telegram_bot) }

  describe '#setup!' do
    let(:webhook_url) { "https://example.com/webhooks/telegram/#{telegram_bot.bot_token}" }
    let(:secret_token) { 'a' * 64 } # 32 bytes hex = 64 chars

    before do
      ENV['TELEGRAM_WEBHOOK_URL'] = 'https://example.com'
      allow(SecureRandom).to receive(:hex).with(32).and_return(secret_token)
    end

    context 'when webhook setup is successful' do
      before do
        stub_request(:post, "https://api.telegram.org/bot#{telegram_bot.bot_token}/setWebhook")
          .with(
            body: hash_including(
              url: webhook_url,
              secret_token: secret_token,
              allowed_updates: array_including('channel_post', 'message_reaction')
            )
          )
          .to_return(
            status: 200,
            body: { ok: true, result: true, description: 'Webhook was set' }.to_json
          )
      end

      it 'generates a webhook secret' do
        expect(SecureRandom).to receive(:hex).with(32).and_return(secret_token)
        service.setup!
      end

      it 'saves webhook secret to database' do
        service.setup!
        expect(telegram_bot.reload.webhook_secret).to eq(secret_token)
      end

      it 'updates last_sync_at timestamp' do
        expect { service.setup! }.to change { telegram_bot.reload.last_sync_at }
      end

      it 'sends secret_token to Telegram API' do
        service.setup!

        expect(WebMock).to have_requested(:post, "https://api.telegram.org/bot#{telegram_bot.bot_token}/setWebhook")
          .with(body: hash_including(secret_token: secret_token))
      end

      it 'logs success' do
        expect(Rails.logger).to receive(:info).with(/Webhook configured for bot #{telegram_bot.id}/)
        service.setup!
      end
    end

    context 'when webhook setup fails' do
      before do
        stub_request(:post, "https://api.telegram.org/bot#{telegram_bot.bot_token}/setWebhook")
          .to_return(
            status: 200,
            body: { ok: false, description: 'Bad Request: invalid webhook URL' }.to_json
          )
      end

      it 'raises an error' do
        expect { service.setup! }.to raise_error(/Failed to set webhook/)
      end

      it 'does not save webhook secret' do
        expect { service.setup! rescue nil }.not_to change { telegram_bot.reload.webhook_secret }
      end
    end
  end

  describe '#delete!' do
    before do
      stub_request(:post, "https://api.telegram.org/bot#{telegram_bot.bot_token}/deleteWebhook")
        .to_return(
          status: 200,
          body: { ok: true, result: true, description: 'Webhook was deleted' }.to_json
        )
    end

    it 'deletes the webhook' do
      result = service.delete!
      expect(result['ok']).to be true
    end
  end

  describe '#info' do
    before do
      stub_request(:post, "https://api.telegram.org/bot#{telegram_bot.bot_token}/getWebhookInfo")
        .to_return(
          status: 200,
          body: {
            ok: true,
            result: {
              url: "https://example.com/webhooks/telegram/#{telegram_bot.bot_token}",
              has_custom_certificate: false,
              pending_update_count: 0
            }
          }.to_json
        )
    end

    it 'returns webhook info' do
      result = service.info
      expect(result['ok']).to be true
      expect(result['result']['url']).to include('/webhooks/telegram/')
    end
  end
end
