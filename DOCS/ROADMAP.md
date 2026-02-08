# ROADMAP - ContentForce
# План разработки монолитного Rails приложения для автоматизации контента

**Версия:** 2.1 (Монолитная архитектура + Notion-style UI)
**Дата создания:** 10 января 2026
**Последнее обновление:** 16 января 2026 (20:45 MSK)
**Статус проекта:** В разработке - Этап 1 ✅ 100%, Этап 2 ✅ 100%, Этап 3 ✅ 100%, Этап 4 ✅ 100%, UI Редизайн ✅ 100%
**Целевая дата MVP:** Март 2026 (12 недель)

**Последняя проверка:** 16 января 2026 (20:45 MSK)
**Реализовано:**
- ✅ Базовая инфраструктура (Rails 8, PostgreSQL, Redis, Docker)
- ✅ Аутентификация (Devise + Telegram OAuth)
- ✅ Основные модели (User, Project, TelegramBot, Post, Subscription)
- ✅ Авторизация (Pundit + политики)
- ✅ CRUD контроллеры для всех ресурсов
- ✅ AI интеграция (OpenRouter API) - **ЗАВЕРШЕНО**
- ✅ AiConfiguration модель - **СОЗДАНА**
- ✅ AiUsageLog модель - **СОЗДАНА**
- ✅ OpenRouter Client - **РЕАЛИЗОВАН**
- ✅ Telegram верификация ботов
- ✅ Telegram публикация постов (PublishService)
- ✅ Telegram webhook сервис
- ✅ Webhook контроллер
- ✅ Background jobs для публикации (PublishPostJob)
- ✅ Post Editor (трехпанельный интерфейс с AI чатом) - **ПЕРЕРАБОТАН В NOTION-STYLE**
- ✅ Stimulus контроллеры (post_editor, chat, theme, calendar, analytics)
- ✅ Active Storage для изображений
- ✅ Administrate админ панель настроена
- ✅ Dashboard и базовые views - **ПЕРЕРАБОТАНЫ В NOTION-STYLE**
- ✅ Landing page
- ✅ **ViewComponent дизайн-система (Button, Card, Input, Sidebar)**
- ✅ **Темная тема (Dark Mode) с ручным управлением** ✨ ОБНОВЛЕНО 16.01.2026
- ✅ **Notion-style типографика и spacing**
- ✅ **Календарь публикаций (Stage 4.1)** ✨ НОВОЕ
- ✅ **Аналитика с графиками (Stage 4.2)** ✨ НОВОЕ
- ✅ **Мульти-канальная архитектура** ✨ НОВОЕ
- ✅ **19 AI моделей с тарифными планами** ✨ НОВОЕ 16.01.2026
- ✅ **DeepSeek Chat как бесплатная модель по умолчанию** ✨ НОВОЕ 16.01.2026
- ✅ **Группировка моделей по тарифам в админке** ✨ НОВОЕ 16.01.2026

**Требует внимания:**
- ⚠️ GitHub Actions CI/CD не настроен
- ⚠️ Robokassa биллинг (Stage 4.3) - не начато
- ⚠️ Unit/Integration тесты (Stage 5) - частично

---

## 📊 Прогресс выполнения

### Этап 1: Базовая настройка монолита (Week 1-2) - **✅ ~95% ЗАВЕРШЕНО**

✅ **Выполнено:**
- Rails 8.0 проект создан и настроен
- PostgreSQL и Redis настроены
- UUID primary keys активированы
- Все необходимые гемы установлены (Devise, Pundit, Telegram Bot, RSpec, и др.)
- Docker и docker-compose.yml готовы
- RSpec с FactoryBot, WebMock, SimpleCov полностью настроен
- Hotwire (Turbo + Stimulus) инициализировано
- Tailwind CSS настроен
- Solid Queue, Solid Cache, Solid Cable готовы
- bin/dev и Procfile.dev работают
- Dashboard с боковым сайдбаром создан
- HealthController создан

❌ **Не выполнено:**
- GitHub Actions CI/CD pipeline (файл не найден)

### Этап 2: Аутентификация и основные модели (Week 3-4) - **~90% ЗАВЕРШЕНО**

✅ **Выполнено:**
- Devise установлен и настроен
- Email confirmation отключен для упрощения разработки
- User модель создана с UUID и Telegram OAuth полями
- Project модель создана с полной функциональностью
- TelegramBot модель создана с шифрованием bot_token
- Post модель создана с workflow методами
- Subscription модель создана с полной функциональностью
- Pundit авторизация полностью настроена
- Все политики (ProjectPolicy, PostPolicy, TelegramBotPolicy) созданы
- ApplicationController настроен с Pundit
- Telegram OAuth интеграция настроена (OmniAuth + Callbacks контроллер)
- Views для аутентификации созданы (Devise views)
- PagesController и home page созданы
- HealthController создан
- Dashboard контроллер и views созданы
- PostsController с полным CRUD создан
- ProjectsController с полным CRUD создан
- TelegramBotsController создан
- API контроллер для AI создан (Api::V1::AiController)
- Routes настроены полностью
- Administrate админка настроена (дашборды + контроллеры)

✅ **Дополнительно выполнено:**
- **Этап 4.1 и 4.2 ЗАВЕРШЕНЫ** (календарь, аналитика)

❌ **Не начато:**
- Этап 4.3 (Robokassa биллинг)
- Этап 5 (полное тестирование и production deployment)

### Этап 3: Интеграция Telegram и AI (Week 5-8) - **✅ 100% ЗАВЕРШЕНО**

✅ **Выполнено:**
- Telegram::VerifyService создан
- Telegram::PublishService создан и исправлен
- Telegram::WebhookService создан (setup!, delete!, info)
- Webhook контроллер создан
- AI::ContentGenerator создан и улучшен (generate, improve, generate_hashtags)
- **AiConfiguration модель создана** ✨
- **AiUsageLog модель создана** ✨
- **OpenRouter Client реализован в lib/openrouter/client.rb** ✨
- **AI::ContentGenerator интегрирован с OpenRouter Client** ✨
- **Трекинг использования AI и подсчет стоимости** ✨
- **Проверка лимитов подписки перед генерацией** ✨
- API контроллер для AI создан (Api::V1::AiController)
- Routes для AI API настроены
- PostsController с editor action создан
- ProjectsController создан
- PublishPostJob для background публикации создан
- Post Editor view создан и **переработан в Notion-style** ✨
- Stimulus контроллеры для редактора созданы (post_editor, chat, **theme**) ✨
- Active Storage для изображений настроен
- Layout для editor создан и **переработан в Notion-style** ✨

✅ **Дополнительно выполнено:**
- **ViewComponent дизайн-система** (Button, Card, Input, Sidebar) ✨
- **Темная тема (Dark Mode)** с ручным переключением пользователем ✨ ОБНОВЛЕНО 16.01.2026
- **Notion-style типографика и spacing** ✨
- **Dashboard переработан в Notion-style** ✨
- **Projects view переработан в Notion-style** ✨
- **Tailwind CSS 4.1 конфигурация** обновлена ✨
- **19 AI моделей вместо 6** (Free, Starter, Pro, Business) ✨ НОВОЕ 16.01.2026
- **Миграция scheduled_at для постов** ✨ НОВОЕ 16.01.2026

---

## Архитектурный подход

**Монолитное Rails приложение** - всё в одном проекте:
- Единая кодовая база
- Единый процесс деплоя
- Упрощенная разработка и отладка
- Встроенные background workers (Solid Queue)
- Server-side rendering с Hotwire (Turbo + Stimulus)
- Минимальное количество внешних зависимостей

---

## Обзор этапов

- **Этап 1:** Базовая настройка монолита (Week 1-2)
- **Этап 2:** Аутентификация и основные модели (Week 3-4)
- **Этап 3:** Интеграция Telegram и AI (Week 5-8)
- **Этап 4:** Календарь, аналитика и биллинг (Week 9-10)
- **Этап 5:** Тестирование и запуск (Week 11-12)

---

## ЭТАП 1: Базовая настройка монолита (Week 1-2)

### 1.1 Инициализация монолитного Rails проекта

#### 1.1.1 Создание проекта
- (X) Создать новый Rails 8.0 проект
  - (X) Выполнить `rails new contentforce --database=postgresql --css=tailwind --javascript=esbuild`
  - (X) Создать файл `.ruby-version` с содержимым `3.3.0`
  - (X) Проверить версию Rails: `rails -v` (должна быть 8.0+)
- (X) Настроить Git
  - (X) `cd contentforce`
  - (X) `git init`
  - (X) Создать `.gitignore` (должен быть сгенерирован Rails)
  - (X) Добавить в `.gitignore`: `.env`, `.env.local`, `/storage/*`, `/tmp/storage/*`
  - (X) Первый коммит: `git add . && git commit -m "Initial Rails 8.0 monolith setup"`
  - ( ) Создать репозиторий на GitHub: `gh repo create contentforce --private --source=.`
  - ( ) Пушнуть: `git push -u origin main`
- ( ) Создать ветки
  - ( ) `git checkout -b development`
  - ( ) `git push -u origin development`

#### 1.1.2 Установка необходимых гемов (всё в одном Gemfile)
- (X) Открыть `Gemfile`
- (X) Добавить базовые гемы:
  ```ruby
  # Database
  gem 'pg', '~> 1.5'

  # Redis для кеша и очередей
  gem 'redis', '~> 5.0'

  # Rails 8 defaults для всего встроенного
  gem 'solid_queue'   # Background jobs (вместо Sidekiq)
  gem 'solid_cache'   # Кеширование (вместо Redis напрямую)
  gem 'solid_cable'   # ActionCable адаптер

  # Аутентификация
  gem 'devise'
  gem 'omniauth'
  gem 'omniauth-telegram'
  gem 'omniauth-rails_csrf_protection'

  # Авторизация
  gem 'pundit'

  # Telegram Bot
  gem 'telegram-bot-ruby'

  # HTTP клиент для внешних API
  gem 'faraday'
  gem 'faraday-retry'

  # File uploads
  gem 'image_processing'  # Для Active Storage
  gem 'aws-sdk-s3'        # S3 для production

  # Admin panel
  gem 'administrate'

  # Security
  gem 'rack-attack'

  # Мониторинг
  gem 'sentry-ruby'
  gem 'sentry-rails'

  group :development, :test do
    gem 'dotenv-rails'    # Environment variables
    gem 'pry-rails'       # Debug
    gem 'rspec-rails'
    gem 'factory_bot_rails'
    gem 'faker'
  end

  group :development do
    gem 'bullet'          # N+1 queries detection
    gem 'letter_opener'   # Preview emails
  end

  group :test do
    gem 'capybara'
    gem 'selenium-webdriver'
    gem 'webmock'
    gem 'vcr'
    gem 'simplecov', require: false
    gem 'shoulda-matchers'
    gem 'database_cleaner-active_record'
  end
  ```
- (X) Выполнить `bundle install`
- (X) Создать `.env.example`:
  ```bash
  # Database
  DATABASE_URL=postgresql://localhost/contentforce_development

  # Redis
  REDIS_URL=redis://localhost:6379/0

  # Telegram Bot (для OAuth)
  TELEGRAM_BOT_TOKEN=7608089982:AAGx-Z4oG6qVIbqlva2Wwbt39nqNSZAi4YU
  TELEGRAM_BOT_USERNAME=your_bot_username

  # OpenRouter AI
  OPENROUTER_API_KEY=your_api_key
  OPENROUTER_SITE_URL=http://localhost:3000
  OPENROUTER_SITE_NAME=ContentForce

  # AWS S3 (для production)
  AWS_ACCESS_KEY_ID=your_key
  AWS_SECRET_ACCESS_KEY=your_secret
  AWS_REGION=us-east-1
  AWS_BUCKET=contentforce-uploads

  # Sentry (опционально)
  SENTRY_DSN=your_sentry_dsn

  # Robokassa (позже)
  ROBOKASSA_MERCHANT_LOGIN=contentforce
  ROBOKASSA_PASSWORD_1=ZBRe0xwoPm18HFXD4R9Q
  ROBOKASSA_PASSWORD_2=gBYNoH2r49xY2Goe7mWe
  ```
- (X) Создать локальный `.env` файл: `cp .env.example .env`
- (X) Заполнить реальные значения в `.env`

#### 1.1.3 Настройка базы данных
- (X) Настроить `config/database.yml`:
  ```yaml
  default: &default
    adapter: postgresql
    encoding: unicode
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    url: <%= ENV['DATABASE_URL'] %>

  development:
    <<: *default
    database: contentforce_development

  test:
    <<: *default
    database: contentforce_test

  production:
    <<: *default
    database: contentforce_production
  ```
- (X) Создать инициализатор для UUID: `config/initializers/generators.rb`:
  ```ruby
  Rails.application.config.generators do |g|
    g.orm :active_record, primary_key_type: :uuid
  end
  ```
- (X) Создать базы данных:
  - (X) `rails db:create`
  - (X) Проверить подключение: `rails db:migrate:status`
- (X) Включить UUID расширение:
  - (X) `rails generate migration EnableUuidExtension`
  - (X) Отредактировать миграцию:
    ```ruby
    class EnableUuidExtension < ActiveRecord::Migration[8.0]
      def change
        enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
      end
    end
    ```
  - (X) `rails db:migrate`

### 1.2 Настройка монолитного деплоя

#### 1.2.1 Простой Dockerfile для монолита
- (X) Создать `Dockerfile`:
  ```dockerfile
  # Используем официальный Ruby образ
  FROM ruby:3.3.0

  # Установка зависимостей
  RUN apt-get update -qq && apt-get install -y \
      nodejs \
      npm \
      postgresql-client \
      libvips \
      imagemagick \
      && rm -rf /var/lib/apt/lists/*

  # Рабочая директория
  WORKDIR /app

  # Копируем Gemfile и устанавливаем gems
  COPY Gemfile Gemfile.lock ./
  RUN bundle install

  # Копируем package.json и устанавливаем npm пакеты
  COPY package.json package-lock.json ./
  RUN npm install

  # Копируем весь код приложения
  COPY . .

  # Precompile assets
  RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

  # Expose порт
  EXPOSE 3000

  # Скрипт запуска
  COPY docker-entrypoint.sh /usr/bin/
  RUN chmod +x /usr/bin/docker-entrypoint.sh
  ENTRYPOINT ["docker-entrypoint.sh"]

  # Команда по умолчанию
  CMD ["rails", "server", "-b", "0.0.0.0"]
  ```
- (X) Создать `docker-entrypoint.sh`:
  ```bash
  #!/bin/bash
  set -e

  # Удаляем старый server.pid если есть
  rm -f /app/tmp/pids/server.pid

  # Запускаем миграции
  bundle exec rails db:migrate

  # Выполняем команду
  exec "$@"
  ```
- (X) Создать `.dockerignore`:
  ```
  .git
  .gitignore
  .env
  .env.*
  tmp/
  log/
  storage/
  node_modules/
  public/assets
  public/packs
  coverage/
  ```

#### 1.2.2 Docker Compose для всего стека
- (X) Создать `docker-compose.yml`:
  ```yaml
  version: '3.9'

  services:
    # PostgreSQL
    db:
      image: postgres:16-alpine
      environment:
        POSTGRES_PASSWORD: password
        POSTGRES_DB: contentforce_development
      volumes:
        - postgres_data:/var/lib/postgresql/data
      ports:
        - "5432:5432"
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U postgres"]
        interval: 10s
        timeout: 5s
        retries: 5

    # Redis
    redis:
      image: redis:7-alpine
      volumes:
        - redis_data:/data
      ports:
        - "6379:6379"
      healthcheck:
        test: ["CMD", "redis-cli", "ping"]
        interval: 10s
        timeout: 3s
        retries: 5

    # Rails монолит (web + workers в одном контейнере)
    web:
      build: .
      command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"
      volumes:
        - .:/app
        - bundle_cache:/usr/local/bundle
      ports:
        - "3000:3000"
      depends_on:
        db:
          condition: service_healthy
        redis:
          condition: service_healthy
      environment:
        DATABASE_URL: postgresql://postgres:password@db:5432/contentforce_development
        REDIS_URL: redis://redis:6379/0
      env_file:
        - .env

    # Solid Queue worker (в том же монолите)
    worker:
      build: .
      command: bundle exec rake solid_queue:start
      volumes:
        - .:/app
        - bundle_cache:/usr/local/bundle
      depends_on:
        - db
        - redis
      environment:
        DATABASE_URL: postgresql://postgres:password@db:5432/contentforce_development
        REDIS_URL: redis://redis:6379/0
      env_file:
        - .env

  volumes:
    postgres_data:
    redis_data:
    bundle_cache:
  ```
- ( ) Создать `docker-compose.override.yml` для development:
  ```yaml
  version: '3.9'

  services:
    web:
      stdin_open: true
      tty: true
  ```
- (X) Протестировать запуск: `docker-compose up`
- (X) Проверить доступность: `curl http://localhost:3000`

### 1.3 Настройка CI/CD для монолита

#### 1.3.1 GitHub Actions
- ( ) Создать `.github/workflows/ci.yml`:
  ```yaml
  name: CI

  on:
    push:
      branches: [ main, development ]
    pull_request:
      branches: [ main, development ]

  jobs:
    test:
      runs-on: ubuntu-latest

      services:
        postgres:
          image: postgres:16
          env:
            POSTGRES_PASSWORD: postgres
            POSTGRES_DB: contentforce_test
          options: >-
            --health-cmd pg_isready
            --health-interval 10s
            --health-timeout 5s
            --health-retries 5
          ports:
            - 5432:5432

        redis:
          image: redis:7
          options: >-
            --health-cmd "redis-cli ping"
            --health-interval 10s
            --health-timeout 5s
            --health-retries 5
          ports:
            - 6379:6379

      steps:
        - uses: actions/checkout@v4

        - name: Setup Ruby
          uses: ruby/setup-ruby@v1
          with:
            ruby-version: 3.3.0
            bundler-cache: true

        - name: Setup Node
          uses: actions/setup-node@v4
          with:
            node-version: 20
            cache: 'npm'

        - name: Install dependencies
          run: |
            npm install
            bundle install --jobs 4 --retry 3

        - name: Setup database
          env:
            RAILS_ENV: test
            DATABASE_URL: postgresql://postgres:postgres@localhost:5432/contentforce_test
          run: |
            bundle exec rails db:create
            bundle exec rails db:migrate

        - name: Run tests
          env:
            RAILS_ENV: test
            DATABASE_URL: postgresql://postgres:postgres@localhost:5432/contentforce_test
            REDIS_URL: redis://localhost:6379/0
          run: bundle exec rspec

        - name: Rubocop
          run: bundle exec rubocop

        - name: Brakeman security scan
          run: bundle exec brakeman -q -z

    build:
      runs-on: ubuntu-latest
      needs: test
      if: github.ref == 'refs/heads/main'

      steps:
        - uses: actions/checkout@v4

        - name: Build Docker image
          run: docker build -t contentforce:latest .
  ```

#### 1.3.2 Скрипт деплоя на Coolify
- ( ) Создать `bin/deploy.sh`:
  ```bash
  #!/bin/bash
  set -e

  echo "🚀 Starting deployment..."

  # Проверка окружения
  if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL not set"
    exit 1
  fi

  # Миграции
  echo "📦 Running migrations..."
  bundle exec rails db:migrate

  # Assets precompile
  echo "🎨 Precompiling assets..."
  bundle exec rails assets:precompile

  # Restart workers
  echo "👷 Restarting workers..."
  pkill -f solid_queue || true

  echo "✅ Deployment completed!"
  ```
- ( ) Сделать исполняемым: `chmod +x bin/deploy.sh`

### 1.4 Настройка монолитного фронтенда

#### 1.4.1 Tailwind CSS
- (X) Проверить `tailwind.config.js` (должен быть создан Rails):
  ```javascript
  module.exports = {
    content: [
      './app/views/**/*.html.erb',
      './app/helpers/**/*.rb',
      './app/javascript/**/*.js',
      './app/components/**/*.{rb,erb}'
    ],
    theme: {
      extend: {
        colors: {
          primary: {
            50: '#eff6ff',
            500: '#3b82f6',
            600: '#2563eb',
            700: '#1d4ed8'
          }
        }
      }
    },
    plugins: [
      require('@tailwindcss/forms'),
      require('@tailwindcss/typography')
    ]
  }
  ```
- ( ) Установить Tailwind плагины:
  - ( ) `npm install -D @tailwindcss/forms @tailwindcss/typography`
- (X) Создать `app/assets/stylesheets/application.tailwind.css`:
  ```css
  @tailwind base;
  @tailwind components;
  @tailwind utilities;

  @layer components {
    /* Кнопки */
    .btn {
      @apply px-4 py-2 rounded-lg font-medium transition-colors;
    }

    .btn-primary {
      @apply btn bg-primary-600 text-white hover:bg-primary-700;
    }

    .btn-secondary {
      @apply btn bg-gray-200 text-gray-800 hover:bg-gray-300;
    }

    /* Карточки */
    .card {
      @apply bg-white rounded-lg shadow-sm border border-gray-200 p-6;
    }

    /* Формы */
    .form-label {
      @apply block text-sm font-medium text-gray-700 mb-1;
    }

    .form-input {
      @apply block w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500;
    }

    .form-error {
      @apply mt-1 text-sm text-red-600;
    }
  }
  ```

#### 1.4.2 Hotwire (Turbo + Stimulus) - всё встроенное
- (X) Проверить `app/javascript/application.js`:
  ```javascript
  // Entry point для всего JavaScript в монолите
  import "@hotwired/turbo-rails"
  import "./controllers"
  ```
- ( ) Установить дополнительные библиотеки:
  - ( ) `npm install alpinejs chart.js flatpickr markdown-it sortablejs`
- (X) Обновить `app/javascript/application.js`:
  ```javascript
  import "@hotwired/turbo-rails"
  import "./controllers"
  import Alpine from 'alpinejs'

  // Alpine для простых интерактивных компонентов
  window.Alpine = Alpine
  Alpine.start()
  ```
- (X) Создать базовую структуру контроллеров:
  - (X) Проверить существование `app/javascript/controllers/index.js`
  - (X) Должен автоматически импортировать все контроллеры

#### 1.4.3 Настройка bin/dev для монолита
- (X) Создать `Procfile.dev`:
  ```
  web: bin/rails server -p 3000
  css: bin/rails tailwindcss:watch
  js: npm run build -- --watch
  worker: bundle exec rake solid_queue:start
  ```
- (X) Установить foreman: `gem install foreman`
- (X) Создать/обновить `bin/dev`:
  ```bash
  #!/usr/bin/env sh

  if ! gem list foreman -i --silent; then
    echo "Installing foreman..."
    gem install foreman
  fi

  foreman start -f Procfile.dev "$@"
  ```
- (X) Сделать исполняемым: `chmod +x bin/dev`
- (X) Протестировать: `bin/dev`

### 1.5 Мониторинг и логирование в монолите

#### 1.5.1 Sentry для мониторинга ошибок
- ( ) Создать проект в Sentry (https://sentry.io)
- ( ) Получить DSN
- ( ) Создать `config/initializers/sentry.rb`:
  ```ruby
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.traces_sample_rate = 0.1
    config.environment = Rails.env

    # Фильтруем чувствительные данные
    config.send_default_pii = false
    config.sanitize_fields = [
      'password', 'password_confirmation', 'bot_token',
      'api_key', 'secret', 'token'
    ]
  end
  ```
- ( ) Протестировать: создать тестовую ошибку в консоли
  - ( ) `rails console`
  - ( ) `Sentry.capture_message("Test error from Rails monolith")`

#### 1.5.2 Health Check endpoint
- (X) Создать `app/controllers/health_controller.rb`:
  ```ruby
  class HealthController < ApplicationController
    skip_before_action :authenticate_user!, if: :devise_controller?

    def index
      checks = {
        database: check_database,
        redis: check_redis,
        workers: check_workers
      }

      status = checks.values.all? { |v| v[:status] == 'ok' } ? :ok : :service_unavailable

      render json: {
        status: status == :ok ? 'healthy' : 'unhealthy',
        timestamp: Time.current,
        checks: checks
      }, status: status
    end

    private

    def check_database
      ActiveRecord::Base.connection.execute('SELECT 1')
      { status: 'ok', message: 'Database connected' }
    rescue => e
      { status: 'error', message: e.message }
    end

    def check_redis
      Redis.new(url: ENV['REDIS_URL']).ping
      { status: 'ok', message: 'Redis connected' }
    rescue => e
      { status: 'error', message: e.message }
    end

    def check_workers
      # Проверка Solid Queue workers
      worker_count = SolidQueue::Process.count
      {
        status: worker_count > 0 ? 'ok' : 'warning',
        message: "#{worker_count} workers running"
      }
    rescue => e
      { status: 'error', message: e.message }
    end
  end
  ```
- (X) Добавить route в `config/routes.rb`:
  ```ruby
  get '/health', to: 'health#index'
  ```
- ( ) Протестировать: `curl http://localhost:3000/health`

---

## ЭТАП 2: Аутентификация и основные модели (Week 3-4)

### 2.1 Devise + Telegram OAuth (всё в монолите)

#### 2.1.1 Установка Devise
- (X) Запустить генератор:
  - (X) `rails generate devise:install`
- (X) Настроить `config/initializers/devise.rb`:
  ```ruby
  Devise.setup do |config|
    config.mailer_sender = 'noreply@contentforce.io'
    config.secret_key = Rails.application.credentials.secret_key_base

    # Модули
    config.password_length = 8..128
    config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
    config.reset_password_within = 6.hours
    config.sign_out_via = :delete

    # Confirmable
    config.reconfirmable = true
    config.allow_unconfirmed_access_for = 2.days
  end
  ```
- ( ) Настроить mailer для development (`config/environments/development.rb`):
  ```ruby
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
  ```
- (X) Добавить в `config/routes.rb`:
  ```ruby
  Rails.application.routes.draw do
    devise_for :users

    root 'pages#home'
  end
  ```

#### 2.1.2 Создание User модели
- (X) Сгенерировать User с Devise:
  - (X) `rails generate devise User`
- (X) Изменить миграцию для UUID и добавить поля:
  ```ruby
  class DeviseCreateUsers < ActiveRecord::Migration[8.0]
    def change
      create_table :users, id: :uuid do |t|
        ## Devise
        t.string :email,              null: false, default: ""
        t.string :encrypted_password, null: false, default: ""
        t.string :reset_password_token
        t.datetime :reset_password_sent_at
        t.datetime :remember_created_at
        t.string :confirmation_token
        t.datetime :confirmed_at
        t.datetime :confirmation_sent_at
        t.string :unconfirmed_email
        t.integer :failed_attempts, default: 0, null: false
        t.string :unlock_token
        t.datetime :locked_at
        t.datetime :current_sign_in_at
        t.datetime :last_sign_in_at
        t.string :current_sign_in_ip
        t.string :last_sign_in_ip

        ## Telegram OAuth
        t.bigint :telegram_id
        t.string :telegram_username
        t.string :first_name
        t.string :last_name
        t.string :avatar_url

        ## Roles
        t.integer :role, default: 0, null: false

        t.timestamps
      end

      add_index :users, :email, unique: true
      add_index :users, :reset_password_token, unique: true
      add_index :users, :confirmation_token, unique: true
      add_index :users, :unlock_token, unique: true
      add_index :users, :telegram_id, unique: true
      add_index :users, :role
    end
  end
  ```
- (X) Запустить миграцию: `rails db:migrate`
- (X) Настроить `app/models/user.rb` (confirmable отключен для упрощения разработки):
  ```ruby
  class User < ApplicationRecord
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable,
           :confirmable, :trackable, :lockable,
           :omniauthable, omniauth_providers: [:telegram]

    # Enums
    enum role: { user: 0, admin: 1 }

    # Ассоциации (добавим позже)
    has_many :projects, dependent: :destroy
    has_many :posts, dependent: :destroy
    has_one :subscription, dependent: :destroy
    has_many :payments, dependent: :destroy

    # Валидации
    validates :email, presence: true, uniqueness: true
    validates :telegram_id, uniqueness: true, allow_nil: true

    # Создание/поиск юзера через Telegram
    def self.from_telegram_auth(auth)
      user = find_or_initialize_by(telegram_id: auth['id'])
      user.assign_attributes(
        telegram_username: auth['username'],
        first_name: auth['first_name'],
        last_name: auth['last_name'],
        avatar_url: auth['photo_url'],
        email: auth['email'] || "telegram_#{auth['id']}@contentforce.io",
        password: Devise.friendly_token[0, 20] # Random password
      )
      user.skip_confirmation! # Telegram уже проверил юзера
      user.save!
      user
    end
  end
  ```

#### 2.1.3 Telegram OAuth
- (X) Настроить OmniAuth (`config/initializers/omniauth.rb`):
  ```ruby
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :telegram,
             ENV['TELEGRAM_BOT_TOKEN'],
             {
               bot_username: ENV['TELEGRAM_BOT_USERNAME'],
               origin_url: ENV['TELEGRAM_ORIGIN_URL'] || 'http://localhost:3000'
             }
  end

  # CSRF protection для OmniAuth
  OmniAuth.config.allowed_request_methods = [:post, :get]
  ```
- (X) Создать callbacks контроллер:
  - (X) `rails generate controller Users::OmniauthCallbacks`
- (X) Настроить `app/controllers/users/omniauth_callbacks_controller.rb`:
  ```ruby
  class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token, only: :telegram

    def telegram
      @user = User.from_telegram_auth(request.env['omniauth.auth']['info'])

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: 'Telegram') if is_navigational_format?
      else
        session['devise.telegram_data'] = request.env['omniauth.auth'].except('extra')
        redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
      end
    end

    def failure
      redirect_to root_path, alert: 'Ошибка аутентификации через Telegram'
    end
  end
  ```
- (X) Обновить routes:
  ```ruby
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  ```

#### 2.1.4 Views для аутентификации
- (X) Сгенерировать Devise views:
  - (X) `rails generate devise:views`
- ( ) Создать layout для auth страниц: `app/views/layouts/auth.html.erb`:
  ```erb
  <!DOCTYPE html>
  <html>
    <head>
      <title>ContentForce - Аутентификация</title>
      <%= csrf_meta_tags %>
      <%= csp_meta_tag %>
      <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
      <%= javascript_importmap_tags %>
    </head>

    <body class="bg-gray-50 min-h-screen flex items-center justify-center">
      <div class="max-w-md w-full">
        <%= yield %>
      </div>
    </body>
  </html>
  ```
- (X) Создать home page: `app/controllers/pages_controller.rb`:
  ```ruby
  class PagesController < ApplicationController
    skip_before_action :authenticate_user!, only: [:home]

    def home
      redirect_to projects_path if user_signed_in?
    end
  end
  ```
- (X) Создать view: `app/views/pages/home.html.erb`

### 2.2 Основные модели в монолите

#### 2.2.1 Модель Project
- (X) Сгенерировать:
  ```bash
  rails generate model Project \
    user:references \
    name:string \
    description:text \
    category:integer \
    default_tone_of_voice:integer \
    default_language:string \
    timezone:string \
    ai_model:string \
    settings:jsonb \
    archived_at:datetime
  ```
- (X) Изменить миграцию на UUID и добавить индексы
- (X) Запустить: `rails db:migrate`
- (X) Настроить модель `app/models/project.rb`:
  ```ruby
  class Project < ApplicationRecord
    belongs_to :user
    has_many :telegram_bots, dependent: :destroy
    has_many :posts, dependent: :destroy
    has_one_attached :logo

    enum category: {
      business: 0, blog: 1, news: 2, entertainment: 3,
      education: 4, technology: 5, health: 6, other: 99
    }

    enum default_tone_of_voice: {
      friendly: 0, professional: 1, enthusiastic: 2,
      formal: 3, casual: 4, emotional: 5,
      informational: 6, sales: 7
    }

    validates :name, presence: true, length: { maximum: 100 }
    validates :category, presence: true
    validates :default_language, inclusion: { in: %w[ru en] }

    scope :active, -> { where(archived_at: nil) }
    scope :archived, -> { where.not(archived_at: nil) }

    def archive!
      update(archived_at: Time.current)
    end

    def unarchive!
      update(archived_at: nil)
    end

    def archived?
      archived_at.present?
    end
  end
  ```

#### 2.2.2 Модель TelegramBot
- (X) Сгенерировать:
  ```bash
  rails generate model TelegramBot \
    project:references \
    bot_token:string \
    bot_username:string \
    chat_id:bigint \
    chat_title:string \
    chat_type:integer \
    verified_at:datetime \
    last_sync_at:datetime \
    status:integer \
    error_message:text
  ```
- (X) Изменить миграцию (UUID + encrypts для bot_token)
- (X) Запустить: `rails db:migrate`
- (X) Настроить модель `app/models/telegram_bot.rb`:
  ```ruby
  class TelegramBot < ApplicationRecord
    belongs_to :project
    has_many :posts, dependent: :nullify
    has_many :subscriber_metrics, class_name: 'ChannelSubscriberMetrics', dependent: :destroy

    encrypts :bot_token

    enum chat_type: { channel: 0, group: 1, supergroup: 2 }
    enum status: { active: 0, inactive: 1, error: 2 }

    validates :bot_token, presence: true
    validates :bot_username, uniqueness: true, allow_nil: true

    after_create :verify_bot
    after_create :setup_webhook

    def verify_bot
      Telegram::VerifyService.new(self).verify!
    rescue => e
      update(status: :error, error_message: e.message)
    end

    def setup_webhook
      Telegram::WebhookService.new(self).setup!
    end

    def telegram_client
      @telegram_client ||= Telegram::Bot::Client.new(bot_token)
    end
  end
  ```

#### 2.2.3 Модель Post
- (X) Сгенерировать:
  ```bash
  rails generate model Post \
    project:references \
    telegram_bot:references \
    user:references \
    title:string \
    content:text \
    formatted_content:text \
    post_type:integer \
    tone_of_voice:integer \
    button_text:string \
    button_url:string \
    status:integer \
    scheduled_at:datetime \
    published_at:datetime \
    telegram_message_id:bigint \
    views_count:integer \
    reactions:jsonb \
    ai_generated:boolean \
    ai_prompt:text \
    metadata:jsonb
  ```
- (X) Изменить миграцию (UUID + defaults)
- (X) Запустить: `rails db:migrate`
- (X) Настроить модель `app/models/post.rb`:
  ```ruby
  class Post < ApplicationRecord
    belongs_to :project
    belongs_to :telegram_bot, optional: true
    belongs_to :user
    has_one_attached :image
    has_many :post_analytics, dependent: :destroy

    enum post_type: { text: 0, image: 1, image_button: 2 }
    enum status: { draft: 0, scheduled: 1, published: 2, failed: 3 }
    enum tone_of_voice: {
      friendly: 0, professional: 1, enthusiastic: 2,
      formal: 3, casual: 4, emotional: 5,
      informational: 6, sales: 7
    }

    validates :content, presence: true, length: { maximum: 4096 }
    validates :button_text, length: { maximum: 64 }, if: -> { post_type == 'image_button' }
    validates :button_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), if: -> { button_url.present? }

    after_create :schedule_publication, if: -> { scheduled? && scheduled_at.present? }

    def schedule_publication!
      PublishPostJob.set(wait_until: scheduled_at).perform_later(id)
    end

    def reschedule_publication!
      schedule_publication!
    end

    def publish!
      Telegram::PublishService.new(self).publish!
    end
  end
  ```

#### 2.2.4 Модель Subscription
- (X) Сгенерировать:
  ```bash
  rails generate model Subscription \
    user:references \
    plan:integer \
    status:integer \
    current_period_start:datetime \
    current_period_end:datetime \
    cancel_at_period_end:boolean \
    canceled_at:datetime \
    trial_ends_at:datetime \
    usage:jsonb \
    limits:jsonb
  ```
- (X) Изменить миграцию (UUID + defaults + индексы)
- ( ) Запустить: `rails db:migrate` (требует запущенной БД)
- (X) Настроить модель (enums, методы проверки лимитов, автоматическое создание)

### 2.3 Pundit авторизация в монолите

#### 2.3.1 Установка Pundit
- (X) Запустить: `rails generate pundit:install`
- (X) Добавить в `ApplicationController`:
  ```ruby
  class ApplicationController < ActionController::Base
    include Pundit::Authorization

    before_action :authenticate_user!
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    private

    def user_not_authorized
      flash[:alert] = "У вас нет прав для этого действия."
      redirect_to(request.referrer || root_path)
    end
  end
  ```

#### 2.3.2 Создание политик
- (X) ProjectPolicy: `rails generate pundit:policy Project`
- (X) PostPolicy: `rails generate pundit:policy Post`
- (X) TelegramBotPolicy: `rails generate pundit:policy TelegramBot`

### 2.4 Administrate (админка в монолите)

#### 2.4.1 Установка
- (X) Запустить: `rails generate administrate:install` (дашборды созданы вручную)
- (X) Создать admin контроллер (Admin::ApplicationController + все контроллеры созданы)
- (X) Создать dashboards для всех моделей (User, Project, Post, TelegramBot, Subscription)
- (X) Добавить routes в config/routes.rb

---

## ЭТАП 3: Интеграция Telegram и AI (Week 5-8)

### 3.1 Telegram сервисы (всё в app/services)

#### 3.1.1 Структура сервисов
- ( ) Создать папки:
  - ( ) `mkdir -p app/services/telegram`
  - ( ) `mkdir -p app/services/ai`
  - ( ) `mkdir -p app/services/payment`

#### 3.1.2 Telegram::VerifyService
- (X) Создать `app/services/telegram/verify_service.rb` (см. детали в Этапе 3.1.2 старого roadmap)

#### 3.1.3 Telegram::PublishService
- (X) Создать `app/services/telegram/publish_service.rb` (исправлен и доработан)

#### 3.1.4 Telegram::WebhookService
- (X) Создать `app/services/telegram/webhook_service.rb` (создан с методами setup!, delete!, info)

#### 3.1.5 Webhook контроллер
- (X) Создать `app/controllers/webhooks/telegram_controller.rb` (см. детали)
- (X) Добавить route: `post '/webhooks/telegram/:bot_token', to: 'webhooks/telegram#receive'`

#### 3.1.6 Background Job для публикации
- (X) Создать `app/jobs/publish_post_job.rb`:
  ```ruby
  class PublishPostJob < ApplicationJob
    queue_as :default
    retry_on Telegram::Bot::Exceptions::ResponseError, wait: :exponentially_longer, attempts: 3

    def perform(post_id)
      post = Post.find(post_id)
      return unless post.scheduled?

      result = post.publish!

      post.update!(
        status: :published,
        published_at: Time.current,
        telegram_message_id: result.message_id
      )

      Analytics::UpdatePostViewsJob.perform_later(post.telegram_bot_id)
    rescue => e
      post.update!(status: :failed, error_message: e.message)
      raise
    end
  end
  ```

### 3.2 OpenRouter AI интеграция - **✅ 100% ЗАВЕРШЕНО**

#### 3.2.1 OpenRouter Client (в lib/)
- (X) Создать `lib/openrouter/client.rb` ✅
- (X) Поддержка 19 AI моделей ✅ ОБНОВЛЕНО 16.01.2026
- (X) Группировка по тарифам (Free, Starter, Pro, Business) ✅

#### 3.2.2 Модели для AI
- (X) Создать `AiConfiguration` модель ✅
- (X) Создать `AiUsageLog` модель ✅
- (X) Расширен список моделей с 6 до 19 ✅ НОВОЕ 16.01.2026
- (X) DeepSeek Chat как модель по умолчанию ✅ НОВОЕ 16.01.2026
- (X) Миграция для обновления дефолтной модели ✅ НОВОЕ 16.01.2026

**Доступные модели:**
- **Free tier (3):** DeepSeek Chat, Gemini 2.0 Flash, Llama 3.2 3B
- **Starter tier (4):** GPT-3.5 Turbo, Claude 3 Haiku, Gemini Pro, Llama 3 8B
- **Pro tier (6):** Claude 3.5 Sonnet, GPT-4 Turbo, GPT-4o, Gemini Pro 1.5, Llama 3 70B, Claude 3 Sonnet
- **Business tier (5):** Claude 3 Opus, GPT-4 Turbo Preview, OpenAI o1 Preview, Gemini Ultra, DeepSeek Coder

#### 3.2.3 AI сервисы
- (X) Создать `app/services/ai/content_generator.rb` ✅
- (X) Поддержка всех 19 моделей ✅
- (X) Проверка доступности модели по тарифу пользователя ✅

#### 3.2.4 API контроллер для AI
- (X) Создать `app/controllers/api/v1/ai_controller.rb`
- (X) Добавить routes в `config/routes.rb`:
  ```ruby
  namespace :api do
    namespace :v1 do
      resources :ai, only: [] do
        collection do
          post :generate
          post :improve
          post :generate_hashtags
        end
      end
    end
  end
  ```

### 3.3 Post Editor (трехпанельный интерфейс) - **✅ 100% ЗАВЕРШЕНО**

#### 3.3.1 Контроллеры
- (X) Создать `PostsController` с action `editor` ✅
- (X) Создать `ProjectsController` ✅

#### 3.3.2 Views
- (X) Создать `app/views/posts/editor.html.erb` ✅
- (X) Трехпанельный интерфейс (AI чат, настройки, preview) ✅
- (X) Создать `app/views/layouts/editor.html.erb` ✅
- (X) Темная тема для редактора ✅ ОБНОВЛЕНО 16.01.2026
- (X) Улучшена контрастность текста в темной теме ✅ НОВОЕ 16.01.2026
- (X) Кнопка отправки с иконкой самолетика ✅ НОВОЕ 16.01.2026

#### 3.3.3 Stimulus контроллеры
- (X) Создать `app/javascript/controllers/post_editor_controller.js` ✅
- (X) Создать `app/javascript/controllers/chat_controller.js` ✅
- (X) Создать `app/javascript/controllers/theme_controller.js` ✅ НОВОЕ 16.01.2026
- (X) Ручное переключение темы (светлая/темная) ✅ ОБНОВЛЕНО 16.01.2026
- (X) Удалено автоопределение системной темы ✅ НОВОЕ 16.01.2026
- (X) Визуальный селектор темы в настройках ✅ НОВОЕ 16.01.2026

#### 3.3.4 Active Storage для изображений
- (X) Установить: `rails active_storage:install` (миграция создана)
- ( ) Запустить: `rails db:migrate` (требует запущенной БД)
- (X) Настроить storage (Post модель обновлена: has_one_attached :image)

---

## ЭТАП 4: Календарь, аналитика и биллинг (Week 9-10) - **✅ 66% ЗАВЕРШЕНО**

### 4.1 Календарь публикаций - **✅ 100% ЗАВЕРШЕНО**

#### 4.1.1 CalendarController
- (X) Создать `app/controllers/calendar_controller.rb` ✅
- (X) Реализовать фильтрацию по проектам и датам ✅
- (X) Подготовить данные для календаря ✅

#### 4.1.2 Views и Stimulus
- (X) Создать `app/views/calendar/index.html.erb` ✅
- (X) Создать `app/javascript/controllers/calendar_controller.js` ✅
- (X) Месячный вид календаря с событиями ✅
- (X) Вид списка с группировкой по датам ✅
- (X) Sidebar с upcoming posts и статистикой ✅
- (X) Навигация по месяцам ✅
- (X) Роут и ссылка в navigation ✅

#### 4.1.3 Database Schema
- (X) Миграция `add_scheduled_at_to_posts` ✅ НОВОЕ 16.01.2026
- (X) Исправлена ошибка 500 с отсутствующей колонкой ✅ НОВОЕ 16.01.2026

### 4.2 Аналитика - **✅ 100% ЗАВЕРШЕНО**

#### 4.2.1 Модели аналитики
- (X) PostAnalytic (views, forwards, reactions, button_clicks) ✅
- (X) ChannelSubscriberMetric (subscriber_count, growth, churn_rate) ✅
- (X) Associations с Post и TelegramBot ✅
- (X) Scopes и helper методы ✅
- (X) Миграции с индексами ✅

#### 4.2.2 Background Jobs
- (X) `app/jobs/analytics/update_post_views_job.rb` ✅
- (X) `app/jobs/analytics/snapshot_channel_metrics_job.rb` ✅
- (X) `app/jobs/analytics/calculate_churn_rate_job.rb` ✅
- (X) `app/services/telegram/analytics_service.rb` ✅

#### 4.2.3 Dashboard аналитики
- (X) AnalyticsController с расчетом метрик ✅
- (X) Views с Chart.js 4.4.1 ✅
- (X) 4 карточки статистики ✅
- (X) 3 графика (views, subscribers, engagement) ✅
- (X) Топ-10 публикаций ✅
- (X) Фильтры по проектам и временным диапазонам ✅
- (X) Роут и ссылка в navigation ✅

### 4.3 Robokassa биллинг

#### 4.3.1 Payment модель и сервис
- ( ) Создать модель Payment
- ( ) Создать `app/services/payment/robokassa_service.rb`

#### 4.3.2 Webhook
- ( ) Создать `app/controllers/webhooks/robokassa_controller.rb`

#### 4.3.3 SubscriptionsController
- ( ) CRUD для подписок
- ( ) Views для тарифов

---

## ЭТАП 5: Тестирование и запуск (Week 11-12)

### 5.1 RSpec настройка
- (X) Установить тестовые гемы
- (X) Настроить `spec/rails_helper.rb`
- (X) Создать фабрики

### 5.2 Тесты
- ( ) Unit тесты (модели)
- ( ) Service тесты
- ( ) Request тесты (контроллеры)
- ( ) System E2E тесты

### 5.3 Security & Performance
- (X) Brakeman scan
- ( ) Bundle audit
- ( ) N+1 queries (Bullet)
- ( ) Performance optimization

### 5.4 Production Deployment
- ( ) Настроить production environment
- ( ) Деплой на Coolify
- ( ) Мониторинг и логирование
- ( ) Backup стратегия

### 5.5 Beta Launch
- ( ) Landing page
- ( ) Beta тестеры
- ( ) Сбор feedback
- ( ) Анонс запуска

---

## Преимущества монолитной архитектуры

✅ **Простота разработки:**
- Один репозиторий, один проект
- Нет сложности с межсервисной коммуникацией
- Легче отлаживать - весь код в одном месте

✅ **Упрощенный деплой:**
- Один Docker контейнер
- Один процесс для деплоя
- Нет проблем с версионированием микросервисов

✅ **Меньше оверхеда:**
- Не нужны message brokers для межсервисной коммуникации
- Прямые вызовы методов вместо HTTP/gRPC
- Единая база данных - нет distributed transactions

✅ **Быстрый старт:**
- Идеально для MVP и малых команд
- Меньше инфраструктурных затрат
- Проще масштабировать вертикально

✅ **Встроенные возможности Rails 8:**
- Solid Queue для jobs
- Solid Cache для кеширования
- Solid Cable для WebSockets
- Всё работает из коробки

---

## Когда мигрировать на микросервисы?

Рассматривать разделение монолита на сервисы только когда:
1. Более 100,000 активных пользователей
2. Команда разработки более 20 человек
3. Явные bottlenecks которые нельзя решить масштабированием
4. Необходимость независимого деплоя разных частей системы

---

**Версия roadmap:** 2.0 (Монолитная архитектура)
**Дата последнего обновления:** 10 января 2026
**Статус:** Готов к разработке

**Telegram Bot Token:** `7608089982:AAGx-Z4oG6qVIbqlva2Wwbt39nqNSZAi4YU`
**Следующий review:** Конец Week 2
