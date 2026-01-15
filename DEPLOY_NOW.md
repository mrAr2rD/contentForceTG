# 🚀 Быстрый деплой на Coolify - ПРЯМО СЕЙЧАС

## ✅ Что уже сделано:

1. ✅ Исправлен `config/database.yml`
2. ✅ Изменения закоммичены и запушены в GitHub
3. ✅ У вас есть DATABASE_URL от PostgreSQL

## 📋 Что нужно сделать (5 минут):

### Шаг 1: Откройте Coolify

Перейдите в ваше приложение ContentForce.

### Шаг 2: Настройте Environment Variables

Нажмите **Environment Variables** → **Add Variable**

Добавьте эти переменные **ПО ОДНОЙ**:

#### 1️⃣ DATABASE_URL (ОБЯЗАТЕЛЬНО)

```
Name: DATABASE_URL
Value: postgresql://postgres:tyVAGamoOg3sl3hMABKBybW9oZ2uIBxJvKIhRXMuCX5tod772H1z1mqPyAsrj5rt@qcwkg0w4ssscks44o48c0k8w:5432/postgres

✅ Runtime: ON (включить!)
❌ Build Time: OFF (выключить!)
```

#### 2️⃣ REDIS_URL

Сначала создайте Redis сервис (если не создан):
- Resources → Add Database → Redis 7
- Скопируйте Internal Connection String
- Используйте формат: `redis://service-name:6379/0`

```
Name: REDIS_URL
Value: redis://[ваш-redis-service-name]:6379/0

✅ Runtime: ON
❌ Build Time: OFF
```

#### 3️⃣ RAILS_MASTER_KEY

```
Name: RAILS_MASTER_KEY
Value: 995a2f3b6ea26667605e7b925ed0b195

✅ Runtime: ON
❌ Build Time: OFF
```

#### 4️⃣ SECRET_KEY_BASE

```
Name: SECRET_KEY_BASE
Value: 7e8e8025083082bbeedda51f96cbda612bb96183538db25a276dca485c2f0ba7df59cbebfbbca7fbb4fefc8d882c20cdc0fb1d1044de9e1fe00af6191a45a121

✅ Runtime: ON
❌ Build Time: OFF
```

#### 5️⃣ RAILS_ENV

```
Name: RAILS_ENV
Value: production

✅ Runtime: ON
✅ Build Time: ON (оба можно)
```

#### 6️⃣ RAILS_SERVE_STATIC_FILES

```
Name: RAILS_SERVE_STATIC_FILES
Value: true

✅ Runtime: ON
✅ Build Time: ON
```

#### 7️⃣ RAILS_LOG_TO_STDOUT

```
Name: RAILS_LOG_TO_STDOUT
Value: true

✅ Runtime: ON
✅ Build Time: ON
```

#### 8️⃣ TELEGRAM_BOT_TOKEN (опционально, но лучше сразу)

```
Name: TELEGRAM_BOT_TOKEN
Value: 7608089982:AAGx-Z4oG6qVIbqlva2Wwbt39nqNSZAi4YU

✅ Runtime: ON
❌ Build Time: OFF
```

#### 9️⃣ OPENROUTER_API_KEY (опционально, для AI)

```
Name: OPENROUTER_API_KEY
Value: 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

✅ Runtime: ON
❌ Build Time: OFF
```

### Шаг 3: Проверьте Port Mapping

1. Settings → Network → Port Mappings
2. Должно быть:
   - **Container Port**: `3000`
   - **Public Port**: `80` или `443`

### Шаг 4: Настройте Health Check

1. Settings → Health Check
2. Установите:
   - **Path**: `/up`
   - **Port**: `3000`
   - **Interval**: `30s`
   - **Timeout**: `10s`
   - **Retries**: `3`

### Шаг 5: Deploy!

1. Нажмите большую кнопку **Deploy**
2. Дождитесь окончания (5-10 минут)
3. Следите за логами

## 📊 Что должно произойти:

### Build phase (3-5 минут):
```
✅ Cloning repository from GitHub
✅ Building Docker image
✅ Installing Ruby gems
✅ Installing Node modules
✅ Precompiling assets
✅ Image built successfully
```

### Runtime phase (1-2 минуты):
```
✅ Starting container
✅ Running database migrations (db:prepare)
✅ Puma starting...
✅ Listening on http://0.0.0.0:3000
✅ Health check passed
```

## ✅ Успех выглядит так:

В логах увидите:
```
=> Booting Puma
=> Rails 8.0.4 application starting in production
* Puma version: 6.5.0 (ruby 3.4.6) ("Fierce Swallow")
* Min threads: 5
* Max threads: 5
* Environment: production
* Listening on http://0.0.0.0:3000
Use Ctrl-C to stop
```

## 🎉 Проверка

После успешного деплоя:

1. **Откройте ваш домен** (или IP)
2. Должна загрузиться главная страница ContentForce
3. Проверьте `/up` → должен вернуть 200 OK

## ❌ Если что-то не работает

### Ошибка: Can't connect to database

**Проверьте:**
1. DATABASE_URL правильно скопирован (без лишних пробелов)
2. DATABASE_URL отмечен как **Runtime Only**
3. PostgreSQL сервис запущен в Coolify

**Исправление:**
```bash
# В Coolify Terminal
echo $DATABASE_URL
```
Должно вывести полный URL. Если пусто → переменная не установлена как Runtime!

### Ошибка: Assets не загружаются (нет стилей)

**Проверьте:**
```env
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

### Ошибка: Missing RAILS_MASTER_KEY

**Проверьте:**
- RAILS_MASTER_KEY добавлен
- Значение: `995a2f3b6ea26667605e7b925ed0b195`
- Отмечен как **Runtime Only**

## 📝 Чеклист перед деплоем

- [ ] DATABASE_URL добавлен и **Runtime Only**
- [ ] REDIS_URL добавлен (создан Redis сервис)
- [ ] RAILS_MASTER_KEY добавлен и **Runtime Only**
- [ ] SECRET_KEY_BASE добавлен и **Runtime Only**
- [ ] RAILS_ENV=production
- [ ] RAILS_SERVE_STATIC_FILES=true
- [ ] RAILS_LOG_TO_STDOUT=true
- [ ] Port mapping: 3000 → 80
- [ ] Health check: /up на порту 3000
- [ ] PostgreSQL сервис запущен
- [ ] Redis сервис запущен
- [ ] Код запушен в GitHub (dev или main ветка)

## 🔥 Частые ошибки

### ❌ DATABASE_URL установлен как Build Time
→ Ошибка: connection to server on socket

**Решение:** Переключите на **Runtime Only**

### ❌ В DATABASE_URL дубликат postgres://
→ Ошибка: Invalid database URL

**Решение:** Используйте формат: `postgresql://user:pass@host:port/db`

### ❌ REDIS_URL указывает на localhost
→ Ошибка: Cannot connect to Redis

**Решение:** Используйте имя сервиса из Coolify, не localhost

### ❌ Неправильный Port Mapping
→ Сайт не открывается

**Решение:** Container Port должен быть `3000`

## 💡 Полезные команды

### Проверка переменных окружения:
```bash
# В Coolify Terminal
env | grep -E "(DATABASE_URL|REDIS_URL|RAILS)"
```

### Проверка подключения к базе:
```bash
./bin/rails runner "puts ActiveRecord::Base.connection.active?"
```

### Перезапуск миграций:
```bash
./bin/rails db:migrate:status
./bin/rails db:migrate
```

### Просмотр логов:
```bash
tail -f log/production.log
```

## 🎯 Итого

После выполнения всех шагов:

1. ✅ Приложение задеплоится
2. ✅ База данных подключится
3. ✅ Миграции выполнятся
4. ✅ Сайт откроется по вашему домену

**Время на всё: ~10-15 минут**

---

## 🆘 Нужна помощь?

Если застряли:

1. Покажите логи из Coolify (последние 50 строк)
2. Проверьте [FIX_COOLIFY_DATABASE.md](./FIX_COOLIFY_DATABASE.md)
3. Используйте [COOLIFY_TROUBLESHOOTING.md](./COOLIFY_TROUBLESHOOTING.md)

**Успешного деплоя! 🚀**
