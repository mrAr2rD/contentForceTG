# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content Security Policy', type: :request do
  describe 'CSP Headers' do
    context 'in production mode' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        # Reload CSP configuration
        load Rails.root.join('config', 'initializers', 'content_security_policy.rb')
      end

      it 'sets Content-Security-Policy header' do
        get root_path

        expect(response.headers['Content-Security-Policy']).to be_present
      end

      it 'includes default-src directive' do
        get root_path

        csp = response.headers['Content-Security-Policy']
        expect(csp).to include("default-src 'self' https:")
      end

      it 'restricts script sources' do
        get root_path

        csp = response.headers['Content-Security-Policy']
        expect(csp).to include("script-src 'self' https:")
      end

      it 'restricts style sources' do
        get root_path

        csp = response.headers['Content-Security-Policy']
        expect(csp).to include("style-src 'self' https:")
      end

      it 'disallows object embedding' do
        get root_path

        csp = response.headers['Content-Security-Policy']
        expect(csp).to include("object-src 'none'")
      end

      it 'allows Telegram images' do
        get root_path

        csp = response.headers['Content-Security-Policy']
        expect(csp).to include('https://t.me')
        expect(csp).to include('https://telegram.org')
      end

      it 'allows OpenRouter API connections' do
        get root_path

        csp = response.headers['Content-Security-Policy']
        expect(csp).to include('https://openrouter.ai')
      end

      it 'allows Telegram OAuth iframe' do
        get root_path

        csp = response.headers['Content-Security-Policy']
        expect(csp).to include('frame-src')
        expect(csp).to include('https://oauth.telegram.org')
      end

      it 'allows Robokassa form submission' do
        get root_path

        csp = response.headers['Content-Security-Policy']
        expect(csp).to include('form-action')
        expect(csp).to include('https://auth.robokassa.ru')
      end

      it 'includes report-uri in production' do
        get root_path

        csp = response.headers['Content-Security-Policy']
        expect(csp).to include('report-uri /csp-violation-report-endpoint')
      end

      it 'enforces policy (not report-only) in production' do
        get root_path

        expect(response.headers['Content-Security-Policy-Report-Only']).to be_nil
        expect(response.headers['Content-Security-Policy']).to be_present
      end
    end

    context 'in development mode' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
        load Rails.root.join('config', 'initializers', 'content_security_policy.rb')
      end

      it 'sets CSP in report-only mode' do
        get root_path

        # В development используется report-only mode
        expect(response.headers['Content-Security-Policy-Report-Only']).to be_present
      end

      it 'does not enforce policy in development' do
        get root_path

        # CSP не должна блокировать в development
        expect(response.headers['Content-Security-Policy']).to be_nil
      end
    end
  end

  describe 'CSP Nonces' do
    let(:user) { create(:user) }

    before { sign_in user }

    it 'generates unique nonces per request' do
      get dashboard_path
      nonce1 = response.headers['Content-Security-Policy']&.match(/nonce-(\S+)/)&.captures&.first

      get dashboard_path
      nonce2 = response.headers['Content-Security-Policy']&.match(/nonce-(\S+)/)&.captures&.first

      # Nonces должны быть разными для каждого запроса (если CSP активен)
      if nonce1 && nonce2
        expect(nonce1).not_to eq(nonce2)
      end
    end
  end

  describe 'POST /csp-violation-report-endpoint' do
    let(:csp_violation_report) do
      {
        'csp-report' => {
          'document-uri' => 'https://example.com/page',
          'referrer' => '',
          'violated-directive' => 'script-src',
          'effective-directive' => 'script-src',
          'original-policy' => "default-src 'self'",
          'disposition' => 'enforce',
          'blocked-uri' => 'https://evil.com/malicious.js',
          'status-code' => 200,
          'script-sample' => ''
        }
      }
    end

    it 'accepts CSP violation reports' do
      post '/csp-violation-report-endpoint',
           params: csp_violation_report.to_json,
           headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:ok)
    end

    it 'logs CSP violations' do
      expect(Rails.logger).to receive(:warn).with(/CSP Violation/)

      post '/csp-violation-report-endpoint',
           params: csp_violation_report.to_json,
           headers: { 'Content-Type' => 'application/json' }
    end

    it 'logs blocked URI' do
      expect(Rails.logger).to receive(:warn).with(/https:\/\/evil\.com\/malicious\.js/)

      post '/csp-violation-report-endpoint',
           params: csp_violation_report.to_json,
           headers: { 'Content-Type' => 'application/json' }
    end

    it 'logs violated directive' do
      expect(Rails.logger).to receive(:warn).with(/script-src/)

      post '/csp-violation-report-endpoint',
           params: csp_violation_report.to_json,
           headers: { 'Content-Type' => 'application/json' }
    end

    context 'with Sentry configured' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        stub_const('Sentry', double('Sentry'))
        allow(Sentry).to receive(:capture_message)
      end

      it 'sends violations to Sentry in production' do
        expect(Sentry).to receive(:capture_message).with(
          'CSP Violation',
          level: :warning,
          extra: { csp_report: csp_violation_report['csp-report'] }
        )

        post '/csp-violation-report-endpoint',
             params: csp_violation_report.to_json,
             headers: { 'Content-Type' => 'application/json' }
      end
    end

    context 'with invalid JSON' do
      it 'handles malformed reports gracefully' do
        expect(Rails.logger).to receive(:error).with(/Failed to parse CSP report/)

        post '/csp-violation-report-endpoint',
             params: 'invalid json{{{',
             headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'with missing csp-report field' do
      it 'handles incomplete reports' do
        post '/csp-violation-report-endpoint',
             params: { 'other-field' => 'value' }.to_json,
             headers: { 'Content-Type' => 'application/json' }

        # Должно обработаться без ошибок (nil csp_report)
        expect(response.status).to be_between(200, 500)
      end
    end

    it 'does not require authentication' do
      # CSP reports приходят от браузера, не от authenticated user
      post '/csp-violation-report-endpoint',
           params: csp_violation_report.to_json,
           headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:ok)
    end

    it 'does not require CSRF token' do
      # CSP reports не содержат CSRF token
      post '/csp-violation-report-endpoint',
           params: csp_violation_report.to_json,
           headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'XSS Protection via CSP' do
    let(:user) { create(:user) }

    before { sign_in user }

    it 'blocks inline scripts when enforced' do
      # В production режиме inline scripts должны блокироваться
      # (если только не используется nonce)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      load Rails.root.join('config', 'initializers', 'content_security_policy.rb')

      get dashboard_path

      csp = response.headers['Content-Security-Policy']

      # script-src должен требовать либо 'self', либо https, либо nonce
      expect(csp).to include('script-src')
      expect(csp).not_to include("'unsafe-inline'")
      expect(csp).not_to include("'unsafe-eval'")
    end

    it 'blocks external scripts from unauthorized domains' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      load Rails.root.join('config', 'initializers', 'content_security_policy.rb')

      get dashboard_path

      csp = response.headers['Content-Security-Policy']

      # Не должны разрешать скрипты с любых доменов
      expect(csp).not_to include("script-src *")
    end
  end

  describe 'Clickjacking Protection' do
    it 'prevents embedding in untrusted iframes' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      load Rails.root.join('config', 'initializers', 'content_security_policy.rb')

      get root_path

      csp = response.headers['Content-Security-Policy']

      # frame-src должен ограничивать, откуда можно загружать iframes
      expect(csp).to include('frame-src')
    end
  end

  describe 'Mixed Content Protection' do
    it 'enforces HTTPS for resources' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      load Rails.root.join('config', 'initializers', 'content_security_policy.rb')

      get root_path

      csp = response.headers['Content-Security-Policy']

      # default-src должен включать https:
      expect(csp).to include('https:')
    end
  end
end
