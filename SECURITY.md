# Security Policy / Политика безопасности

## Реализованные меры безопасности

### 🔒 Аутентификация и авторизация

#### P0.1: Telegram Webhook Authentication
- **Защита**: Валидация webhook подписи с webhook_secret
- **Реализация**: `Webhooks::TelegramController` + миграция `add_webhook_secret_to_telegram_bots`
- **Стандарт**: HMAC-SHA256 подпись от Telegram

#### P0.2: Robokassa SHA-256 Signature
- **Защита**: Upgrade с MD5 на SHA-256 для платёжных webhook
- **Реализация**: `PaymentConfiguration#valid_result_signature?`
- **Защита от**: Timing attacks через `ActiveSupport::SecurityUtils.secure_compare`

#### P0.3: Telegram OAuth Validation
- **Защита**: Проверка HMAC-SHA256 подписи данных Telegram OAuth
- **Реализация**: `User.verify_telegram_auth_data`
- **Проверки**:
  - Валидация подписи через HMAC-SHA256
  - Проверка свежести данных (< 24 часов)
  - Защита от timing attacks

#### P2.5: Devise Lockable - Brute Force Protection
- **Защита**: Блокировка аккаунта после неудачных попыток входа
- **Настройки**:
  - Максимум попыток: 5
  - Стратегия: `:failed_attempts`
  - Разблокировка: `:both` (email + автоматически через 1 час)
- **Стандарт**: OWASP рекомендация (3-5 попыток для критичных систем)

### 🛡️ Rate Limiting & DDoS Protection

#### P2.1: Rack::Attack
- **Защита**: Rate limiting для всех endpoints
- **Реализация**: `config/initializers/rack_attack.rb`
- **Лимиты**:
  - Общие запросы: 300 req/min по IP
  - Авторизация: 5 попыток в 20 секунд
  - Регистрация: 3 попытки в час
  - AI запросы: 20 в минуту на проект
  - Telegram webhooks: 100 в минуту на бота
  - Robokassa webhooks: 50 в минуту
  - API: 60 req/min на пользователя
- **Exponential Backoff**: Бан на 1 час после 2 нарушений за 10 минут
- **Redis**: Распределённое хранилище для production

### 🔐 Data Protection

#### Active Record Encryption
- **Шифрование**:
  - `TelegramBot#bot_token` - encrypted
  - `PaymentConfiguration#password_1` - encrypted
  - `PaymentConfiguration#password_2` - encrypted
- **Алгоритм**: AES-256-GCM (Rails 7+ encryption)
- **Ключи**: ENV переменные (`AR_ENCRYPTION_PRIMARY_KEY`, etc.)

#### P0.4: Parameter Filtering
- **Защита**: Фильтрация чувствительных параметров в логах
- **Файл**: `config/initializers/filter_parameter_logging.rb`
- **Фильтруются**:
  - `:password`, `:password_confirmation`
  - `:bot_token`, `:api_key`, `:secret`
  - `:credit_card_number`, `:cvv`
  - `:otp_secret`, `:otp_code`
  - Custom regex: `/secret|token|key/i`

### 🖼️ File Upload Security

#### P2.2: Magic Bytes Validation
- **Защита**: Проверка реального типа файла по magic bytes
- **Реализация**: `ImageValidatable` concern
- **Проверки**:
  1. Размер файла (max 10MB для постов, 5MB для статей)
  2. Content-Type валидация
  3. **Magic bytes проверка через Marcel::MimeType** (критично!)
  4. Mismatch logging при несоответствии типов
- **Защита от**:
  - PHP shell disguised as image (`.php.jpg`)
  - Executable disguised as image (`.exe.png`)
  - SVG с XSS payload
  - HTML/JavaScript файлы
- **Модели**: `Post`, `Article`

### 🚫 Mass Assignment Protection

#### P2.3: Strong Parameters
- **Защита**: Предотвращение unauthorized изменения критичных полей
- **Критичные поля**:
  - `Post#status` - ЗАПРЕЩЕНО (только через `publish!`, `schedule!`)
  - `User#role` - только для админов
  - `Subscription#status` - только для админов
- **Защита от**:
  - Bypass бизнес-логики
  - Privilege escalation
  - Публикация невалидных данных
- **Self-role protection**: Админ не может изменить собственную роль

### 💳 Payment Security

#### P2.4: Race Condition Protection
- **Защита**: Pessimistic locking для платежей
- **Реализация**: `payment.with_lock` + `subscription.with_lock`
- **Проверки**:
  - Idempotency check (платёж уже обработан?)
  - Status validation (валидный статус для обработки?)
  - Atomic transactions
- **Защита от**:
  - Дублирующие webhook от Robokassa
  - Concurrent payment processing
  - Double subscription activation

### 🔒 HTTP Security Headers

#### Security Headers
- `X-Frame-Options: SAMEORIGIN` - защита от clickjacking
- `X-Content-Type-Options: nosniff` - защита от MIME sniffing
- `X-XSS-Protection: 1; mode=block` - XSS фильтр
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy: camera=(), microphone=(), geolocation=()`

#### Session Security
- **Файл**: `config/initializers/session_store.rb`
- **Настройки**:
  - `secure: true` (HTTPS only в production)
  - `httponly: true` (защита от JavaScript доступа)
  - `same_site: :lax` (CSRF защита)

### 🔍 Security Logging

- **Unauthorized admin access attempts**: IP + User ID
- **Pundit authorization failures**: User + Action
- **Telegram OAuth failures**: Invalid signature
- **Robokassa webhook failures**: Invalid signature
- **MIME type mismatch**: Подделка content_type

## Security Best Practices

### Для разработчиков

1. **Никогда не доверяйте пользовательскому вводу**
   - Всегда используйте strong parameters
   - Валидируйте все данные
   - Экранируйте вывод в views

2. **Используйте параметризованные запросы**
   ```ruby
   # ✅ ПРАВИЛЬНО
   User.where(email: params[:email])
   User.where("name = ?", params[:name])

   # ❌ ОПАСНО
   User.where("name = '#{params[:name]}'")
   ```

3. **Проверяйте типы файлов по magic bytes**
   ```ruby
   # ✅ ПРАВИЛЬНО - использовать ImageValidatable concern
   include ImageValidatable
   validate :validate_image_with_magic_bytes, if: -> { image.attached? }

   # ❌ ОПАСНО - проверка только content_type
   validates :image, content_type: ['image/jpeg']
   ```

4. **Используйте database locks для критичных операций**
   ```ruby
   # ✅ ПРАВИЛЬНО
   payment.with_lock do
     return if payment.completed? # Idempotency
     payment.mark_as_completed!
   end

   # ❌ ОПАСНО - race condition
   payment.mark_as_completed! if payment.pending?
   ```

5. **Не используйте `.permit!` в Strong Parameters**
   ```ruby
   # ✅ ПРАВИЛЬНО
   params.require(:post).permit(:title, :content)

   # ❌ ОПАСНО
   params.require(:post).permit! # Разрешает ВСЁ
   ```

## Security Testing

### Запуск security тестов

```bash
# Все security тесты
rspec spec/requests/*security*
rspec spec/requests/*protection*

# Конкретные категории
rspec spec/requests/telegram_oauth_spec.rb        # Telegram OAuth
rspec spec/requests/robokassa_race_condition_spec.rb  # Race conditions
rspec spec/requests/mass_assignment_protection_spec.rb  # Mass assignment
rspec spec/requests/rack_attack_spec.rb           # Rate limiting
rspec spec/models/concerns/image_validatable_spec.rb   # File upload
rspec spec/features/devise_lockable_spec.rb       # Brute force

# Security scan
bundle exec brakeman
```

### Coverage

- Telegram webhook signature validation ✅
- Robokassa signature validation ✅
- Telegram OAuth HMAC validation ✅
- Race conditions в платежах ✅
- Mass assignment protection ✅
- Magic bytes file validation ✅
- Rate limiting ✅
- Brute force protection ✅

## Reporting Security Vulnerabilities

Если вы нашли уязвимость безопасности:

1. **НЕ** создавайте публичный issue
2. Отправьте детали на: security@contentforce.ru
3. Включите:
   - Описание уязвимости
   - Шаги для воспроизведения
   - Потенциальное влияние
   - Предложенное решение (опционально)

Мы рассмотрим все сообщения в течение 48 часов.

## Security Checklist для Production

- [ ] Настроить SSL/TLS (force_ssl = true)
- [ ] Настроить Active Record Encryption ключи
- [ ] Настроить Redis для Rack::Attack
- [ ] Включить HSTS header
- [ ] Ограничить CORS если используется API
- [ ] Настроить backup базы данных
- [ ] Включить monitoring (Sentry)
- [ ] Регулярно обновлять зависимости (`bundle update`)
- [ ] Запускать `bundle audit` для проверки CVE
- [ ] Настроить firewall правила
- [ ] Ограничить доступ к admin панели по IP
- [ ] Настроить 2FA для админов (опционально)

## Dependencies Security

```bash
# Проверка уязвимостей в gem'ах
bundle audit check --update

# Проверка npm packages
npm audit

# Static analysis
bundle exec brakeman -A -q
```

## Security Updates Log

| Дата | Версия | Изменения |
|------|--------|-----------|
| 2026-02-12 | 1.0.0 | Полная реализация security мер P0-P2 |
| - | - | Rack::Attack rate limiting |
| - | - | Devise lockable brute force protection |
| - | - | Magic bytes file validation |
| - | - | Race condition protection для платежей |
| - | - | Mass assignment protection |
| - | - | Telegram/Robokassa webhook signatures |

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Devise Security](https://github.com/heartcombo/devise#strong-parameters)
- [Rack::Attack](https://github.com/rack/rack-attack)
- [Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)
