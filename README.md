# ContentForce

AI-powered контент-менеджмент платформа для Telegram с интеграцией GPT-4, Claude и других AI моделей.

## Требования

- Ruby 3.3.0
- Rails 8.0.4
- PostgreSQL 16
- Redis 7
- Node.js (для esbuild и Tailwind CSS)
- Docker и Docker Compose (опционально, для локальной разработки)

## Установка

### 1. Клонирование репозитория

```bash
git clone <repository-url>
cd contentforce
```

### 2. Установка зависимостей

```bash
bundle install
yarn install
```

### 3. Настройка окружения

Скопируйте `.env.example` в `.env` и настройте переменные окружения:

```bash
cp .env.example .env
```

Отредактируйте `.env` файл и добавьте свои значения для:
- `TELEGRAM_BOT_TOKEN` - токен вашего Telegram бота
- `OPENROUTER_API_KEY` - API ключ для OpenRouter
- Другие переменные при необходимости

### 4. Запуск с Docker Compose (рекомендуется)

```bash
# Запустить PostgreSQL и Redis
docker-compose up -d db redis

# Создать базу данных
rails db:create db:migrate

# Запустить приложение
bin/dev
```

### 5. Запуск без Docker

Убедитесь, что PostgreSQL и Redis запущены локально, затем:

```bash
# Создать базу данных
rails db:create db:migrate

# Запустить приложение
bin/dev
```

Приложение будет доступно по адресу: http://localhost:3000

## Структура проекта

```
app/
├── controllers/      # Контроллеры
├── models/          # Модели
├── views/           # Views (Hotwire/Turbo)
├── javascript/      # JavaScript (Stimulus)
├── assets/          # Статические ресурсы
└── services/        # Service Objects
    ├── telegram/    # Telegram Bot сервисы
    ├── ai/          # AI интеграция
    └── analytics/   # Аналитика
```

## Тестирование

```bash
# Запустить все тесты
bundle exec rspec

# Запустить конкретный тест
bundle exec rspec spec/models/user_spec.rb

# Запустить с покрытием кода
COVERAGE=true bundle exec rspec
```

## Разработка

### Запуск сервера разработки

```bash
bin/dev
```

Это запустит:
- Rails сервер на порту 3000
- esbuild для JavaScript
- Tailwind CSS для стилей

### Работа с фоновыми задачами

Solid Queue используется для фоновых задач:

```bash
bin/jobs
```

### Консоль Rails

```bash
rails console
```

## Архитектура

ContentForce использует монолитную архитектуру с Service Objects паттерном:

- **Backend**: Ruby on Rails 8.0
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Database**: PostgreSQL 16 с UUID первичными ключами
- **Cache**: Solid Cache (Rails 8)
- **Background Jobs**: Solid Queue (Rails 8)
- **Real-time**: Solid Cable (Rails 8)
- **Authentication**: Devise + Telegram OAuth
- **Authorization**: Pundit
- **AI Integration**: OpenRouter (Claude, GPT-4, Gemini)
- **Telegram Bot**: telegram-bot-ruby

## Полезные команды

```bash
# Проверка безопасности
bin/brakeman

# Линтинг кода
bin/rubocop

# Создание миграции
rails generate migration MigrationName

# Создание модели
rails generate model ModelName field:type

# Создание контроллера
rails generate controller ControllerName

# Откат миграции
rails db:rollback

# Сброс базы данных
rails db:reset
```

## Deployment

Проект использует Kamal для деплоя:

```bash
# Первый деплой
kamal setup

# Обновление
kamal deploy

# Просмотр логов
kamal logs
```

Для настройки деплоя отредактируйте `config/deploy.yml` и `.kamal/secrets`.

## Документация

- [PRD.md](../PRD.md) - Полное описание продукта
- [ROADMAP.md](../ROADMAP.md) - План разработки
- [CLAUDE.md](../CLAUDE.md) - Руководство для Claude Code

## Лицензия

Proprietary
