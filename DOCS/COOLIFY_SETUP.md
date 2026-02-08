# 🚀 Деплой ContentForce на Coolify

## Обновлено: 15 января 2026 (после редизайна)

### ✨ Что изменилось

- ✅ Добавлены новые модели (AiConfiguration, AiUsageLog)
- ✅ Добавлен OpenRouter Client
- ✅ Добавлен ViewComponent
- ✅ Обновлен Tailwind CSS до 4.1
- ✅ Добавлена темная тема

---

## 📋 Требования

### В Coolify должно быть создано:

1. **PostgreSQL 16** сервис
   - Имя: `contentforce-db`
   - Версия: 16-alpine
   - Получите DATABASE_URL из настроек

2. **Application** из GitHub
   - Repository: ваш репозиторий
   - Branch: main
   - Build Pack: **Dockerfile**
   - Port: **3000**

---

## 🔐 Переменные окружения (Runtime Only!)

### Обязательные переменные:

```bash
# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=995a2f3b6ea26667605e7b925ed0b195
SECRET_KEY_BASE=<сгенерируйте: bundle exec rails secret>
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true

# Database (из PostgreSQL сервиса в Coolify)
DATABASE_URL=postgresql://postgres:password@contentforce-db:5432/contentforce_production

# OpenRouter AI (обязательно!)
OPENROUTER_API_KEY=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
OPENROUTER_SITE_URL=https://ваш-домен.com
OPENROUTER_SITE_NAME=ContentForce

# Telegram Bot
TELEGRAM_BOT_TOKEN=7608089982:AAGx-Z4oG6qVIbqlva2Wwbt39nqNSZAi4YU
TELEGRAM_BOT_USERNAME=ваш_бот_username
TELEGRAM_ORIGIN_URL=https://ваш-домен.com
```

### Опциональные переменные:

```bash
# Sentry (мониторинг ошибок)
SENTRY_DSN=<ваш_sentry_dsn>

# AWS S3 (для production файлов)
AWS_ACCESS_KEY_ID=<ваш_ключ>
AWS_SECRET_ACCESS_KEY=<ваш_секрет>
AWS_REGION=eu-central-1
AWS_BUCKET=contentforce-production
```

---

## 🐳 Dockerfile готов

Текущий [`Dockerfile`](contentforce/Dockerfile) уже оптимизирован для production:

✅ **Особенности:**
- Multi-stage build (уменьшает размер образа)
- Ruby 3.4.6 + Node.js 24.12.0
- Автоматическая установка gems и npm packages
- Precompile assets
- Thruster + Puma для production
- Автоматическая миграция БД через docker-entrypoint
- Non-root user для безопасности

✅ **Новые зависимости учтены:**
- view_component gem
- lookbook gem (только development, не попадет в production)
- Tailwind CSS 4.1
- Все новые модели и сервисы

---

## 📝 Пошаговая инструкция

### Шаг 1: Создать PostgreSQL сервис

1. В Coolify: **Services** → **+ Add Service**
2. Выбрать **PostgreSQL 16**
3. Настроить:
   - Name: `contentforce-db`
   - Database: `contentforce_production`
   - Username: `postgres`
   - Password: (сгенерируется автоматически)
4. **Deploy**
5. Скопировать **DATABASE_URL** из настроек

---

### Шаг 2: Создать Application

1. В Coolify: **Projects** → **+ Add Application**
2. Выбрать **GitHub Repository**
3. Настроить:
   - Repository: `ваш-username/contentForceTG`
   - Branch: `main`
   - Build Pack: **Dockerfile**
   - Port: **3000**
   - Base Directory: `contentforce`

---

### Шаг 3: Добавить переменные окружения

В разделе **Environment Variables** добавить все переменные из списка выше.

**⚠️ ВАЖНО:** Все секретные переменные должны быть **"Runtime Only"**!

---

### Шаг 4: Настроить домен

1. В настройках Application: **Domains**
2. Добавить ваш домен
3. Включить **HTTPS** (Let's Encrypt)
4. Дождаться выпуска SSL сертификата

---

### Шаг 5: Deploy!

1. Нажать **Deploy**
2. Дождаться завершения build (~5-10 минут)
3. Проверить логи на ошибки

---

## ✅ Проверка после деплоя

### 1. Health Check

```bash
curl https://ваш-домен.com/health
```

**Ожидаемый ответ:**
```json
{
  "status": "healthy",
  "timestamp": "2026-01-15T13:54:00Z",
  "checks": {
    "database": {"status": "ok"},
    "redis": {"status": "ok"},
    "workers": {"status": "ok"}
  }
}
```

### 2. Проверить главную страницу

```bash
curl https://ваш-домен.com
```

Должна открыться landing page.

### 3. Проверить темную тему

Откройте в браузере и нажмите кнопку луны в sidebar.

### 4. Проверить AI генерацию

1. Зарегистрируйтесь
2. Создайте проект
3. Откройте AI Редактор
4. Попробуйте сгенерировать пост

---

## 🐛 Troubleshooting

### Ошибка: "Database connection failed"

**Решение:**
1. Проверьте DATABASE_URL (должен быть Runtime Only)
2. Убедитесь что PostgreSQL сервис запущен
3. Проверьте что имя сервиса совпадает в DATABASE_URL

### Ошибка: "Assets not found"

**Решение:**
1. Добавьте `RAILS_SERVE_STATIC_FILES=true`
2. Пересоберите: **Redeploy**

### Ошибка: "OpenRouter API key not configured"

**Решение:**
1. Добавьте `OPENROUTER_API_KEY` (Runtime Only)
2. Проверьте что ключ валидный
3. Пересоберите: **Redeploy**

### Ошибка: "ViewComponent not found"

**Решение:**
1. Проверьте что `view_component` в Gemfile
2. Пересоберите образ: **Redeploy**
3. Проверьте логи build

### Темная тема не работает

**Решение:**
1. Проверьте что Tailwind CSS скомпилирован
2. Проверьте что `theme_controller.js` загружается
3. Откройте DevTools → Console для ошибок

---

## 📊 Мониторинг

### Логи в Coolify

```
Application → Logs → Live Logs
```

**Что смотреть:**
- Ошибки подключения к БД
- Ошибки AI API
- Ошибки Telegram Bot
- Performance warnings

### Метрики

```
Application → Metrics
```

**Отслеживать:**
- CPU usage
- Memory usage
- Response time
- Error rate

---

## 🔄 Обновление приложения

### После git push:

1. Coolify автоматически обнаружит изменения (если настроен webhook)
2. Или вручную: **Redeploy**

### Миграции выполняются автоматически

Благодаря [`bin/docker-entrypoint`](contentforce/bin/docker-entrypoint):
```bash
./bin/rails db:prepare
```

Это выполнит:
- `db:create` (если БД не существует)
- `db:migrate` (новые миграции)
- `db:seed` (если нужно)

---

## 📦 Что включено в Docker образ

### Gems (production):
- rails 8.1.2
- pg (PostgreSQL)
- redis
- solid_cache, solid_queue, solid_cable
- devise, pundit
- telegram-bot-ruby
- faraday, faraday-retry
- **view_component** ✨
- administrate
- sentry-ruby, sentry-rails
- thruster (production server)

### JavaScript:
- @hotwired/stimulus
- @hotwired/turbo-rails
- @tailwindcss/cli 4.1.18
- esbuild

### Assets:
- Precompiled CSS (Tailwind 4.1)
- Precompiled JavaScript (esbuild)
- Все изображения и шрифты

---

## 🎯 Финальный чеклист

- [ ] PostgreSQL сервис создан и запущен
- [ ] DATABASE_URL скопирован
- [ ] Все переменные окружения добавлены (Runtime Only)
- [ ] Домен настроен с HTTPS
- [ ] Application создан из GitHub
- [ ] Build Pack = Dockerfile
- [ ] Port = 3000
- [ ] Base Directory = contentforce
- [ ] Deploy выполнен успешно
- [ ] Health check возвращает "healthy"
- [ ] Главная страница открывается
- [ ] Регистрация работает
- [ ] Темная тема переключается
- [ ] AI генерация работает

---

## 🎉 Готово!

После успешного деплоя у вас будет:

- ✅ Работающее Rails приложение
- ✅ Notion-style интерфейс с темной темой
- ✅ AI генерация через OpenRouter
- ✅ Telegram Bot интеграция
- ✅ Автоматические миграции
- ✅ HTTPS с Let's Encrypt
- ✅ Мониторинг и логи

**Приложение доступно:** https://ваш-домен.com

---

## 📞 Поддержка

Если возникли проблемы:

1. Проверьте логи в Coolify
2. Проверьте переменные окружения (Runtime Only!)
3. Проверьте что PostgreSQL запущен
4. Проверьте health endpoint: `/health`

---

**Версия:** 0.3.0  
**Дата:** 15 января 2026  
**Статус:** ✅ Готово к деплою на Coolify
