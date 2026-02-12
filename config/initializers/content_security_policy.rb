# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob, "https://t.me", "https://telegram.org"
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https
    # Разрешаем WebSocket подключения для Hotwire/Turbo
    policy.connect_src :self, "https://openrouter.ai", "wss://*"
    # Разрешаем Telegram OAuth iframe
    policy.frame_src   :self, "https://oauth.telegram.org"
    # Разрешаем отправку форм на Robokassa
    policy.form_action :self, "https://auth.robokassa.ru"

    # Specify URI for violation reports
    if Rails.env.production?
      policy.report_uri "/csp-violation-report-endpoint"
    end
  end

  # Generate session nonces for permitted inline scripts and styles
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report violations without enforcing the policy (только в development)
  config.content_security_policy_report_only = Rails.env.development?
end
