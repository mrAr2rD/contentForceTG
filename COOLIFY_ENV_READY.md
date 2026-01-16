# ✅ Ready-to-Use Coolify Environment Variables

## Копируйте эти переменные в Coolify

### 1. Database Configuration

**ВАЖНО:** Используйте `postgresql://` вместо `postgres://`

```env
DATABASE_URL=postgresql://postgres:tyVAGamoOg3sl3hMABKBybW9oZ2uIBxJvKIhRXMuCX5tod772H1z1mqPyAsrj5rt@qcwkg0w4ssscks44o48c0k8w:5432/postgres
```

### 2. Redis Configuration

**TODO:** Замените на ваш Redis service name из Coolify

```env
REDIS_URL=redis://[ваш-redis-service-name]:6379/0
```

Как найти Redis service name:
1. Откройте Coolify → Resources
2. Найдите Redis сервис
3. Скопируйте Internal Connection String
4. Используйте имя хоста из этого URL

### 3. Rails Configuration

```env
RAILS_ENV=production
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

### 4. Security Keys

```env
RAILS_MASTER_KEY=995a2f3b6ea26667605e7b925ed0b195
SECRET_KEY_BASE=7e8e8025083082bbeedda51f96cbda612bb96183538db25a276dca485c2f0ba7df59cbebfbbca7fbb4fefc8d882c20cdc0fb1d1044de9e1fe00af6191a45a121
```

### 5. Telegram Bot

```env
TELEGRAM_BOT_TOKEN=7608089982:AAGx-Z4oG6qVIbqlva2Wwbt39nqNSZAi4YU
TELEGRAM_BOT_USERNAME=contentforce_bot
TELEGRAM_ORIGIN_URL=https://ваш-домен.com
```

**TODO:** Замените `https://ваш-домен.com` на ваш фактический домен

### 6. OpenRouter AI

```env
OPENROUTER_API_KEY=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
OPENROUTER_API_URL=https://openrouter.ai/api/v1
OPENROUTER_SITE_URL=https://ваш-домен.com
OPENROUTER_SITE_NAME=ContentForce
```

**TODO:** Замените `https://ваш-домен.com` на ваш фактический домен

---

## 🔧 Как добавить в Coolify

### Шаг 1: Откройте Environment Variables

1. Зайдите в Coolify
2. Выберите ваше приложение
3. Перейдите в **Environment Variables**

### Шаг 2: Добавьте переменные

**КРИТИЧНО: Отметьте как RUNTIME ONLY!**

Для каждой переменной:
1. Нажмите **Add Variable**
2. Name: `имя переменной`
3. Value: `значение`
4. ✅ **Build Time**: ВЫКЛЮЧЕНО
5. ✅ **Runtime**: ВКЛЮЧЕНО (Runtime Only!)

**Runtime Only переменные:**
- `DATABASE_URL` ⚠️ **Runtime Only**
- `REDIS_URL` ⚠️ **Runtime Only**
- `RAILS_MASTER_KEY` ⚠️ **Runtime Only**
- `SECRET_KEY_BASE` ⚠️ **Runtime Only**
- `TELEGRAM_BOT_TOKEN` ⚠️ **Runtime Only**
- `OPENROUTER_API_KEY` ⚠️ **Runtime Only**

**Build Time + Runtime (можно оставить оба):**
- `RAILS_ENV`
- `RAILS_MAX_THREADS`
- `WEB_CONCURRENCY`
- `RAILS_SERVE_STATIC_FILES`
- `RAILS_LOG_TO_STDOUT`

### Шаг 3: Проверка Port Mapping

1. Settings → **Network**
2. Port Mappings:
   - **Container Port:** `3000`
   - **Public Port:** `80` (или `443` если SSL)

### Шаг 4: Health Check

1. Settings → **Health Check**
   - **Path:** `/up`
   - **Port:** `3000`
   - **Interval:** `30s`
   - **Timeout:** `10s`
   - **Retries:** `3`

### Шаг 5: Deploy!

1. Нажмите **Deploy**
2. Дождитесь завершения build (5-10 минут)
3. Проверьте логи

---

## 🔍 После деплоя - Проверка

### 1. Проверьте логи

В Coolify → **Logs** → Container Logs

Ищите строку:
```
=> Booting Puma
=> Rails 8.0.4 application starting in production
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Puma version: 6.x.x (ruby 3.4.6-p0) ("...")
* Min threads: 5
* Max threads: 5
* Environment: production
* Listening on http://0.0.0.0:3000
```

### 2. Откройте приложение

Перейдите на ваш домен или IP адрес сервера.

Должна открыться главная страница ContentForce.

### 3. Проверьте Health Check

```bash
curl https://ваш-домен.com/up
```

Должно вернуть: `200 OK`

### 4. Проверьте базу данных

В Coolify Terminal:

```bash
./bin/rails runner "puts User.count"
```

Должно вывести число (0 если нет пользователей).

---

## ⚠️ Если что-то не работает

### Ошибка: Can't connect to database

**Проверьте:**

1. DATABASE_URL начинается с `postgresql://` (не `postgres://`)
2. Имя хоста правильное (из Coolify Resources)
3. Пароль скопирован полностью
4. Переменная отмечена как **Runtime Only**

**Попробуйте:**

```bash
# В Coolify Terminal
./bin/rails db:create
./bin/rails db:migrate
```

### Ошибка: Assets не загружаются (нет CSS)

**Проверьте:**

```env
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

**Пересоберите:**

```bash
./bin/rails assets:precompile RAILS_ENV=production
```

### Ошибка: Missing RAILS_MASTER_KEY

**Проверьте:**

1. `RAILS_MASTER_KEY` добавлен в Coolify
2. Значение: `995a2f3b6ea26667605e7b925ed0b195`
3. Отмечено как **Runtime Only**

### Ошибка: Redis connection failed

**Проверьте:**

1. Redis сервис создан в Coolify
2. REDIS_URL содержит правильное имя сервиса
3. Формат: `redis://service-name:6379/0`

---

## 📋 Финальный чеклист

Перед деплоем убедитесь:

- [ ] `DATABASE_URL` начинается с `postgresql://` ✅
- [ ] `DATABASE_URL` содержит правильный хост из Coolify
- [ ] `REDIS_URL` содержит правильное имя Redis сервиса
- [ ] Все секретные переменные отмечены **Runtime Only**
- [ ] `RAILS_MASTER_KEY` и `SECRET_KEY_BASE` добавлены
- [ ] Port mapping: Container `3000` → Public `80`
- [ ] Health check настроен на `/up` порт `3000`
- [ ] PostgreSQL сервис запущен в Coolify
- [ ] Redis сервис запущен в Coolify
- [ ] Домен добавлен (опционально)

---

## 🚀 Готово к деплою!

После настройки всех переменных:

1. Нажмите **Deploy** в Coolify
2. Дождитесь окончания build
3. Проверьте логи
4. Откройте приложение в браузере

**Успешный деплой выглядит так:**

```
✅ Build successful
✅ Container started
✅ Health check passed
✅ Application running on port 3000
```

---

## 📞 Нужна помощь?

1. Проверьте логи в Coolify
2. Изучите [COOLIFY_TROUBLESHOOTING.md](./COOLIFY_TROUBLESHOOTING.md)
3. Запустите локально: `bin/check-env`
