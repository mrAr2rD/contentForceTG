# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ContentForce** is a **monolithic Rails 8.1 application** for automating content creation and publishing to Telegram and social networks using AI. The system is built as a single, unified codebase with server-side rendering using Hotwire (Turbo + Stimulus).

## Architecture Philosophy

**Монолитный подход (Monolithic Architecture):**
- Единая кодовая база - весь код в одном Rails приложении
- Прямые вызовы методов между компонентами (не HTTP/gRPC)
- Единая база данных PostgreSQL с UUID
- Встроенные background workers через Solid Queue (Rails 8)
- Server-side rendering с минимальным JavaScript
- Простота разработки, деплоя и отладки

## Technology Stack

### Backend (Monolith)
- **Framework**: Ruby on Rails 8.1.2 (монолит)
- **Ruby Version**: 3.4.6
- **Database**: PostgreSQL 16 with UUID primary keys
- **Cache/Queue**: Redis 7 + Solid Queue/Cache/Cable (Rails 8 defaults)
- **Background Jobs**: Solid Queue (встроенный в Rails 8, вместо Sidekiq)
- **Authentication**: Devise with Telegram OAuth (omniauth-telegram)
- **Authorization**: Pundit
- **Telegram Integration**: telegram-bot-ruby gem
- **AI Integration**: OpenRouter API (multi-model support: Claude, GPT, Gemini)
- **File Storage**: Active Storage (local dev, AWS S3 production)
- **Admin Panel**: Administrate

### Frontend (Server-Side Rendering)
- **JavaScript**: Hotwire (Turbo + Stimulus) - минимальный JS
- **CSS**: Tailwind CSS 4.x (с новым CSS-first конфигом)
- **Build Tools**: esbuild for JS, Tailwind CLI for CSS
- **Charts**: Chart.js для графиков аналитики
- **Date Picker**: Flatpickr
- **Drag & Drop**: SortableJS для календаря
- **Markdown**: Markdown-it

### Infrastructure
- **Containerization**: Docker (один контейнер для всего монолита)
- **Deployment**: Coolify (self-hosted PaaS)
- **Monitoring**: Sentry для ошибок
- **Testing**: RSpec with FactoryBot, Capybara, WebMock, VCR

## Development Commands

```bash
# Setup
bundle install
npm install
rails db:create db:migrate db:seed

# Development (запуск всего монолита)
bin/dev  # Starts Rails server, CSS watcher, JS builder, Solid Queue workers

# Или через Docker Compose
docker-compose up  # Запускает db, redis, web, worker

# Testing
rspec                          # Run all tests
rspec spec/models              # Run model tests
rspec spec/requests            # Run request tests
rspec spec/system              # Run system tests
rspec spec/services            # Run service tests

# Code quality
rubocop                        # Lint Ruby code
rubocop -a                     # Auto-fix linting issues
bundle exec brakeman           # Security vulnerability scan

# Database
rails db:migrate               # Run pending migrations
rails db:rollback              # Rollback last migration
rails db:reset                 # Drop, create, migrate, seed

# Console
rails console                  # Rails console
rails dbconsole               # Direct database console

# Background Jobs (Solid Queue)
bundle exec rake solid_queue:start  # Запуск workers вручную

# Docker
docker-compose up              # Start all services
docker-compose down            # Stop all services
docker-compose logs -f web     # View web container logs
docker-compose exec web rails console  # Console в контейнере
```

## Project Structure (Monolithic)

```
contentforce/
├── app/
│   ├── controllers/           # Все контроллеры в одном месте
│   │   ├── application_controller.rb
│   │   ├── projects_controller.rb
│   │   ├── posts_controller.rb
│   │   ├── calendar_controller.rb
│   │   ├── subscriptions_controller.rb
│   │   ├── api/v1/            # API endpoints
│   │   │   └── ai_controller.rb
│   │   ├── webhooks/          # Webhook контроллеры
│   │   │   ├── telegram_controller.rb
│   │   │   └── robokassa_controller.rb
│   │   ├── admin/             # Administrate
│   │   └── users/
│   │       └── omniauth_callbacks_controller.rb
│   ├── models/                # Все модели в одном месте
│   │   ├── user.rb
│   │   ├── project.rb
│   │   ├── telegram_bot.rb
│   │   ├── post.rb
│   │   ├── subscription.rb
│   │   ├── payment.rb
│   │   ├── ai_configuration.rb
│   │   ├── ai_usage_log.rb
│   │   └── analytics/
│   │       ├── post_analytics.rb
│   │       ├── channel_subscriber_metrics.rb
│   │       └── subscriber_change.rb
│   ├── services/              # Service objects (логика бизнеса)
│   │   ├── telegram/
│   │   │   ├── verify_service.rb
│   │   │   ├── publish_service.rb
│   │   │   ├── webhook_service.rb
│   │   │   └── analytics_service.rb
│   │   ├── ai/
│   │   │   ├── content_generator.rb
│   │   │   ├── post_improver.rb
│   │   │   └── hashtag_generator.rb
│   │   └── payment/
│   │       └── robokassa_service.rb
│   ├── jobs/                  # Background jobs (Solid Queue)
│   │   ├── publish_post_job.rb
│   │   └── analytics/
│   │       ├── update_post_views_job.rb
│   │       ├── snapshot_channel_metrics_job.rb
│   │       └── calculate_churn_rate_job.rb
│   ├── policies/              # Pundit авторизация
│   │   ├── project_policy.rb
│   │   ├── post_policy.rb
│   │   └── telegram_bot_policy.rb
│   ├── views/                 # ERB templates (server-side rendering)
│   ├── javascript/            # Minimal JS (Hotwire)
│   │   ├── application.js
│   │   └── controllers/       # Stimulus controllers
│   │       ├── post_editor_controller.js
│   │       ├── chat_controller.js
│   │       ├── calendar_controller.js
│   │       └── charts_controller.js
│   └── assets/
│       └── stylesheets/
│           └── application.tailwind.css
├── lib/
│   └── openrouter/           # OpenRouter API client
│       └── client.rb
├── config/
│   ├── routes.rb             # Все маршруты в одном файле
│   ├── database.yml
│   └── initializers/
│       ├── devise.rb
│       ├── omniauth.rb
│       ├── sentry.rb
│       └── generators.rb    # UUID по умолчанию
├── db/
│   └── migrate/              # Все миграции
├── spec/                     # RSpec tests
├── Dockerfile                # Один образ для всего
├── docker-compose.yml        # Полный стек (db, redis, web, worker)
└── Procfile.dev             # Development: web, css, js, worker
```

## Architecture Overview (Monolithic)

### Unified Codebase Benefits

**Вся функциональность в одном приложении:**
- Нет network latency между компонентами
- Прямые вызовы Ruby методов вместо HTTP
- Единая транзакционная модель (нет distributed transactions)
- Легче отлаживать - весь код в одном месте
- Проще деплоить - один Docker контейнер

### Service-Oriented Design (внутри монолита)

Используем паттерн Service Objects для организации бизнес-логики:

#### 1. **`Telegram::*` Services**
Все сервисы для работы с Telegram Bot API в одном namespace:
- `Telegram::VerifyService` - Bot token verification and permissions checking
- `Telegram::WebhookService` - Webhook setup and configuration
- `Telegram::PublishService` - Post publishing to Telegram channels
- `Telegram::AnalyticsService` - Fetching channel statistics

Пример использования в контроллере:
```ruby
# app/controllers/telegram_bots_controller.rb
def create
  @bot = current_user.project.telegram_bots.create!(bot_params)
  # Сервис вызывается напрямую (не через HTTP)
  Telegram::VerifyService.new(@bot).verify!
  redirect_to @bot
end
```

#### 2. **`AI::*` Services**
AI content generation через OpenRouter (все в монолите):
- `AI::ContentGenerator` - Main AI content generation service
- `AI::PostImprover` - Post improvement (shorten, lengthen, add emojis, etc.)
- `AI::HashtagGenerator` - Hashtag generation
- Supports multiple models: Claude (Sonnet/Opus), GPT-4, Gemini Pro
- Usage tracking через `AiUsageLog` модель

Пример:
```ruby
# app/controllers/api/v1/ai_controller.rb
def generate
  generator = AI::ContentGenerator.new(
    project: current_project,
    user: current_user
  )
  content = generator.generate(prompt: params[:prompt])
  render json: { content: content }
end
```

#### 3. **`Analytics::*` Jobs**
Background jobs для сбора аналитики (Solid Queue):
- `Analytics::UpdatePostViewsJob` - Post view statistics updates
- `Analytics::SnapshotChannelMetricsJob` - Daily channel metrics snapshots
- `Analytics::CalculateChurnRateJob` - Subscriber churn calculations

Запускаются через:
```ruby
Analytics::UpdatePostViewsJob.perform_later(telegram_bot_id)
# или отложенно:
Analytics::SnapshotChannelMetricsJob.set(wait_until: tomorrow_midnight).perform_later(bot_id)
```

### Background Jobs Architecture (Solid Queue)

**Solid Queue** - встроенная в Rails 8 система для background jobs:
- Хранит jobs в PostgreSQL (не Redis)
- Не требует дополнительного процесса (Redis не нужен для jobs)
- Retry logic встроен
- Запускается одной командой: `bundle exec rake solid_queue:start`

Основные jobs:
- `PublishPostJob` - Scheduled post publishing
- `Analytics::*` jobs - Metrics collection
- Retry на ошибки с exponential backoff

Пример job:
```ruby
class PublishPostJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(post_id)
    post = Post.find(post_id)
    return unless post.scheduled? || post.draft?

    # Post#publish! handles status update, published_at, and telegram_message_id
    post.publish!
  end
end
```

### Webhook Handlers (в монолите)

Webhooks обрабатываются обычными Rails контроллерами:
- `Webhooks::TelegramController` - Handles Telegram bot events (subscribers, reactions, views)
- `Webhooks::RobokassaController` - Payment processing webhooks
- All webhooks skip CSRF: `skip_before_action :verify_authenticity_token`

### Database Schema Patterns

- **UUID Primary Keys**: All tables use UUID for better distribution and security
- **JSONB Columns**: Flexible metadata storage (`settings`, `metadata`, `reactions`)
- **Encrypted Fields**: `bot_token` uses Rails 7+ `encrypts` attribute
- **Enums**: Status fields, types, and roles use Rails enums (integer-backed)
- **Soft Deletes**: `archived_at` timestamp for projects instead of hard deletion

### Key Models & Relationships

```
User (UUID)
  ├── has_many :projects
  ├── has_many :posts
  ├── has_one :subscription
  └── has_many :payments

Project (UUID)
  ├── belongs_to :user
  ├── has_many :telegram_bots
  ├── has_many :posts
  └── has_one_attached :logo

TelegramBot (UUID)
  ├── belongs_to :project
  ├── has_many :posts
  ├── has_many :subscriber_metrics
  └── encrypts :bot_token

Post (UUID)
  ├── belongs_to :project
  ├── belongs_to :user
  ├── belongs_to :telegram_bot (optional)
  ├── has_one_attached :image
  ├── has_many :post_analytics
  ├── enum status: [:draft, :scheduled, :published, :failed]
  └── error_details (text) - хранит сообщение об ошибке при failed

Subscription (UUID)
  ├── belongs_to :user
  ├── has_many :payments
  └── jsonb :usage, :limits
```

### Frontend Architecture (Server-Side)

**Hotwire-First Approach** - минимум JavaScript:
- Большинство интерактивности через Turbo Frames и Turbo Streams
- Stimulus controllers только для complex UI (editor, charts, calendar)
- Tailwind CSS 4.x для стилей (CSS-first configuration)

**Three-Panel Layout** для post editor:
- Left (30%): AI Chat interface - conversational AI assistant
- Center (20%): Settings panel - post configuration
- Right (50%): Live preview - Telegram post preview

**Stimulus Controllers** (minimal):
- `post_editor_controller.js` - Main post editor orchestration
- `chat_controller.js` - AI chat interface with API calls
- `calendar_controller.js` - Post scheduling calendar with drag & drop
- `charts_controller.js` - Chart.js integration for analytics

**Responsive Design**:
- Mobile-first Tailwind breakpoints
- Grid layout collapses to single column on mobile
- Desktop shows full three-panel layout at `lg:` breakpoint

## AI Integration Details

### OpenRouter Configuration (в монолите)

OpenRouter client в `lib/openrouter/client.rb`:
```ruby
# Использование:
client = OpenRouter::Client.new
response = client.chat(
  model: 'anthropic/claude-3.5-sonnet',
  messages: [
    { role: 'system', content: system_prompt },
    { role: 'user', content: user_prompt }
  ],
  temperature: 0.7,
  max_tokens: 2000
)
```

Supported models:
- Claude 3.5 Sonnet, Claude 3 Opus
- GPT-4 Turbo, GPT-3.5
- Gemini Pro
- Llama 3

Configuration в `AiConfiguration` model (singleton):
- Default model selection
- Temperature (creativity)
- Max tokens (response length)
- Custom system prompts
- Fallback models на случай ошибок

### AI Features

1. **Content Generation** - Generate posts from prompts with tone/style control
2. **Chat Interface** - Real-time conversational AI for iterative content creation
3. **Context Awareness** - AI knows project settings, previous posts, brand voice
4. **Usage Tracking** - All AI requests logged in `ai_usage_logs` table for billing/analytics
5. **Subscription Limits** - Проверка лимитов перед каждым AI request
6. **Free Models** - Бесплатные модели не расходуют лимит подписки (`AiConfiguration.free_model?`)

## Testing Strategy

### RSpec Structure

```bash
spec/
├── models/              # Model tests (validations, associations, methods)
├── services/            # Service object tests (mock external APIs)
├── requests/            # Controller tests (API endpoints)
├── system/              # E2E tests with Capybara
├── jobs/                # Background job tests
└── policies/            # Pundit policy tests
```

### Key Testing Patterns

```ruby
# External API mocking
stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
  .to_return(status: 200, body: mock_response.to_json)

# Background job testing
expect {
  post.schedule_publication!
}.to have_enqueued_job(PublishPostJob).with(post.id).at(post.scheduled_at)

# Factory usage
create(:post, :with_telegram_bot, status: :scheduled)

# Pundit policy testing
expect(ProjectPolicy.new(user, project)).to permit_action(:update)
```

## Environment Variables

Critical environment variables required for development:

```bash
# Database
DATABASE_URL=postgresql://localhost/contentforce_development

# Redis (для cache, не для jobs)
REDIS_URL=redis://localhost:6379/0

# Telegram Bot (для OAuth)
TELEGRAM_BOT_TOKEN=7608089982:AAGx-Z4oG6qVIbqlva2Wwbt39nqNSZAi4YU
TELEGRAM_BOT_USERNAME=your_bot_username
TELEGRAM_ORIGIN_URL=http://localhost:3000

# OpenRouter AI (required for AI features)
OPENROUTER_API_KEY=<api_key>
OPENROUTER_SITE_URL=http://localhost:3000
OPENROUTER_SITE_NAME=ContentForce

# AWS S3 (для production file uploads)
AWS_ACCESS_KEY_ID=<key>
AWS_SECRET_ACCESS_KEY=<secret>
AWS_REGION=us-east-1
AWS_BUCKET=contentforce-uploads

# Monitoring
SENTRY_DSN=<dsn>  # Optional but recommended

# Payments (Robokassa - Russian payment gateway)
ROBOKASSA_MERCHANT_LOGIN=<login>
ROBOKASSA_PASSWORD_1=<password>
ROBOKASSA_PASSWORD_2=<password>
```

## Security Considerations

- **Rate Limiting**: Rack::Attack configured for API endpoints
- **CSRF Protection**: Enabled for all forms, skipped only for webhooks
- **Encrypted Attributes**: Bot tokens encrypted at rest with Rails `encrypts`
- **XSS Prevention**: HTML sanitization in JS controllers before innerHTML usage
- **Authentication**: Devise with secure defaults, Telegram OAuth
- **Authorization**: Pundit policies for all resources
- **Security Scanning**: Brakeman in CI/CD pipeline
- **Input Validation**: Strong parameters, URL format validation
- **Database Indexes**: Unique index on `bot_token` for fast webhook lookup

## Deployment (Monolithic)

The application deploys as a **single Docker container** on Coolify:

1. Build один Docker образ для всего монолита
2. Health check endpoint at `/health` проверяет db, redis, workers
3. Database migrations run automatically via `docker-entrypoint.sh`
4. Background workers запускаются в отдельном контейнере (тот же образ, другая команда)
5. GitHub Actions CI/CD triggers Coolify webhook on main branch push

Deployment process:
```bash
# Local testing
docker-compose up

# Production deploy (через Coolify)
git push origin main  # Triggers GitHub Actions → Coolify
```

## Key Business Logic

### Post Publishing Flow (в монолите)

1. User creates post (manual or AI-generated) → `PostsController#create`
2. Post can be published immediately or scheduled
3. Scheduled posts enqueue `PublishPostJob` via `after_create` callback
4. Job runs at scheduled time, calls `Telegram::PublishService`
5. Service publishes via Bot API, updates post status
6. Webhook receives engagement data → `Webhooks::TelegramController`
7. Background jobs periodically update metrics

Все это происходит в одном приложении, нет HTTP calls между сервисами.

### Subscription & Billing

- Freemium model: Free tier with AI request limits
- Paid tiers: Starter (590₽), Pro (1490₽), Business (2990₽)
- Payment processing via Robokassa (Russian payment gateway)
- Subscription status checked before AI requests via Pundit policies
- Usage tracked in `Subscription#usage` JSONB column

Usage limit check example:
```ruby
class AiPolicy < ApplicationPolicy
  def generate?
    user.subscription.can_use?(:ai_generations_per_month)
  end
end
```

### Multi-Channel Support

- Each project can have multiple Telegram bots
- Bots verified on creation (token + permissions check via `Telegram::VerifyService`)
- Posts can target specific bot/channel or default
- Future: Support for VK, Instagram, Facebook, Twitter/X

## Monolithic Architecture Benefits

✅ **Простота разработки:**
- Весь код в одном месте
- Нет сложности с API contracts между сервисами
- Легче debugging - полный stack trace
- Один язык, один фреймворк

✅ **Упрощенный деплой:**
- Один Docker образ
- Один процесс для деплоя
- Нет версионирования микросервисов
- Rollback в один клик

✅ **Меньше оверхеда:**
- Нет network latency
- Прямые вызовы методов (не HTTP)
- Единая транзакционная модель
- Не нужны message brokers

✅ **Быстрый старт:**
- Идеально для MVP
- Малые команды (1-5 человек)
- Меньше инфраструктурных затрат
- Проще масштабировать вертикально

✅ **Rails 8 встроенные возможности:**
- Solid Queue для jobs (не нужен Sidekiq)
- Solid Cache для кеширования
- Solid Cable для WebSockets
- Всё работает из коробки

## When to Scale Beyond Monolith

Рассматривать разделение на микросервисы только когда:
1. **Более 100,000 активных пользователей**
2. **Команда разработки более 20 человек**
3. **Явные bottlenecks** которые нельзя решить вертикальным масштабированием
4. **Необходимость независимого деплоя** разных частей системы

До этого момента - монолит идеален.

## Common Development Tasks

### Adding a new feature
1. Create model if needed: `rails g model FeatureName`
2. Create service object in `app/services/`
3. Create controller: `rails g controller Features`
4. Add routes to `config/routes.rb`
5. Create views with Hotwire
6. Add Stimulus controller if complex interactivity needed
7. Write RSpec tests
8. Run `rubocop -a` before committing

### Adding a background job
1. Create job: `rails g job MyJob`
2. Implement `perform` method
3. Enqueue: `MyJob.perform_later(args)`
4. Test with RSpec: `expect { ... }.to have_enqueued_job(MyJob)`

### Adding AI functionality
1. Use `AI::ContentGenerator` service
2. Check subscription limits via Pundit
3. Track usage in `AiUsageLog`
4. Handle errors gracefully

## Code Style

The project follows **rubocop-rails-omakase** - Rails default linting rules (minimalist, no debates).

Run `rubocop -a` to auto-fix style issues before committing.

## Support and Documentation

- **GitHub Issues**: https://github.com/mrAr2rD/contentForceTG/issues

---

## Changelog

### 2026-02-06: Security & Performance Audit

**Исправленные проблемы:**
- ✅ Включено шифрование `bot_token` в TelegramBot
- ✅ Исправлена XSS уязвимость в `chat_controller.js` (HTML sanitization)
- ✅ Исправлен race condition в `PublishPostJob` (убрано дублирование статуса)
- ✅ Добавлен уникальный индекс на `telegram_bots.bot_token`
- ✅ Исправлен N+1 в `AnalyticsController#get_top_posts`
- ✅ Добавлено поле `error_details` в Post для хранения ошибок
- ✅ Удалён неиспользуемый `hello_controller.js`
- ✅ Обновлены версии в документации (Ruby 3.4.6, Rails 8.1.2, Tailwind 4.x)
