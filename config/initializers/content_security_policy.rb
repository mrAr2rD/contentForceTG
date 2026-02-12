# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# ОТКЛЮЧЕНО: CSP может блокировать стили и внешние ресурсы (Google Fonts, Yandex.Metrika)
# Раскомментируйте код ниже, если захотите включить CSP в будущем

# Rails.application.configure do
#   config.content_security_policy do |policy|
#     policy.default_src :self, :https
#     policy.font_src    :self, :https, :data, "https://fonts.gstatic.com"
#     policy.style_src   :self, :https, :unsafe_inline, "https://fonts.googleapis.com"
#     policy.script_src  :self, :https, :unsafe_inline, "https://mc.yandex.ru"
#     policy.img_src     :self, :https, :data, :blob, "https://t.me", "https://telegram.org", "https://mc.yandex.ru"
#     policy.object_src  :none
#     policy.connect_src :self, "https://openrouter.ai", "https://mc.yandex.ru", "wss://*"
#     policy.frame_src   :self, "https://oauth.telegram.org"
#     policy.form_action :self, "https://auth.robokassa.ru"
#
#     if Rails.env.production?
#       policy.report_uri "/csp-violation-report-endpoint"
#     end
#   end
#
#   config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
#   config.content_security_policy_nonce_directives = %w[script-src style-src]
#   config.content_security_policy_report_only = true
# end
