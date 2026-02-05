# CLAUDE.md

## Project Overview

**ContentForce** — монолитное Rails 8.1.2 приложение для автоматизации создания и публикации контента в Telegram с использованием AI.

## Technology Stack

- **Ruby** 3.4.6, **Rails** 8.1.2, **PostgreSQL** 16, **Redis** 7
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS 4.x
- **Auth**: Devise + Telegram OAuth, Pundit
- **Jobs**: Solid Queue (Rails 8 default)
- **AI**: OpenRouter API (Claude, GPT-4, Gemini)
- **Storage**: Active Storage (local dev, S3 production)
- **Admin**: Administrate

## Development Commands

```bash
# Setup
bundle install && npm install
rails db:create db:migrate db:seed

# Development
bin/dev                              # Запуск всего (web, css, js, workers)
docker-compose up                    # Или через Docker

# Testing
rspec                                # Все тесты
rspec spec/models                    # Только модели
rspec spec/path/to_spec.rb           # Один файл
rspec spec/path/to_spec.rb:42        # Один тест на строке 42

# Code quality
rubocop -a                           # Auto-fix linting
bundle exec brakeman                 # Security scan

# Database
rails db:migrate                     # Миграции
rails db:rollback                    # Откат
rails console                        # Консоль
```

## Architecture

### Service Objects

Бизнес-логика в `app/services/`:

- **Telegram::*** — `VerifyService`, `PublishService`, `WebhookService`, `AnalyticsService`
- **AI::*** — `ContentGenerator`, `PostImprover`, `HashtagGenerator`
- **Payment::*** — `RobokassaService`

### Background Jobs (Solid Queue)

- `PublishPostJob` — отложенная публикация постов
- `Analytics::UpdatePostViewsJob` — обновление просмотров
- `Analytics::SnapshotChannelMetricsJob` — снапшоты метрик

### Key Models

```
User
├── has_many :projects
├── has_one :subscription
└── has_many :payments

Project
├── belongs_to :user
├── has_many :telegram_bots
└── has_many :posts

TelegramBot
├── belongs_to :project
├── has_many :posts
└── encrypts :bot_token

Post
├── belongs_to :project, :user
├── belongs_to :telegram_bot (optional)
├── enum status: [:draft, :scheduled, :published, :failed]
└── error_details (text)

Subscription
├── belongs_to :user
└── jsonb :usage, :limits
```

### Database Patterns

- UUID primary keys везде
- JSONB для гибких данных (`settings`, `usage`)
- `encrypts :bot_token` для токенов
- Enums для статусов (integer-backed)

## Testing

```ruby
# Мокаем внешние API
stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
  .to_return(status: 200, body: mock_response.to_json)

# Jobs
expect { post.schedule! }.to have_enqueued_job(PublishPostJob)

# Factories
create(:post, :with_telegram_bot, status: :scheduled)

# Policies
expect(ProjectPolicy.new(user, project)).to permit_action(:update)
```

## Environment Variables

```bash
# Required
DATABASE_URL=postgresql://localhost/contentforce_development
REDIS_URL=redis://localhost:6379/0
OPENROUTER_API_KEY=<key>

# Telegram OAuth
TELEGRAM_BOT_TOKEN=<token>
TELEGRAM_BOT_USERNAME=<username>
TELEGRAM_ORIGIN_URL=http://localhost:3000

# Production
AWS_ACCESS_KEY_ID=<key>
AWS_SECRET_ACCESS_KEY=<secret>
AWS_BUCKET=contentforce-uploads
SENTRY_DSN=<dsn>
ROBOKASSA_MERCHANT_LOGIN=<login>
ROBOKASSA_PASSWORD_1=<password>
ROBOKASSA_PASSWORD_2=<password>
```

## Code Style

- **Linter**: rubocop-rails-omakase (Rails defaults)
- **Комментарии**: на русском языке (см. `.qoder/rules/russian.md`)
- **Skills**: см. `.claude/skills/` для специализированных правил

```bash
rubocop -a  # Auto-fix перед коммитом
```

## Key Business Logic

### Post Publishing Flow

1. User создаёт пост → `PostsController#create`
2. Scheduled posts → `PublishPostJob` (Solid Queue)
3. Job вызывает `Telegram::PublishService`
4. Webhook получает engagement → `Webhooks::TelegramController`

### Subscription & Billing

- Free tier с лимитами AI
- Платные тарифы: Starter (590₽), Pro (1490₽), Business (2990₽)
- Оплата через Robokassa
- Usage в `Subscription#usage` JSONB

### AI Integration

- OpenRouter client: `lib/openrouter/client.rb`
- Модели: Claude, GPT-4, Gemini
- Бесплатные модели не расходуют лимит (`AiConfiguration.free_model?`)
- Логирование в `ai_usage_logs`

## Deployment

```bash
docker-compose up              # Local
git push origin main           # Production (Coolify)
```

Health check: `/health`
