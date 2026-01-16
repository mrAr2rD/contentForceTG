# 🔧 Исправление ошибки подключения к базе данных в Coolify

## ❌ Ошибка

```
ActiveRecord::ConnectionNotEstablished: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed
```

Rails пытается подключиться к PostgreSQL через Unix socket вместо сети.

## ✅ Причина

1. `DATABASE_URL` не установлен как **Runtime** переменная в Coolify
2. Или `config/database.yml` неправильно настроен

## 🔧 Решение

### Шаг 1: Обновите config/database.yml

Я уже исправил файл `config/database.yml` для вас!

**Было (неправильно):**
```yaml
production:
  primary:
    database: contentforce_production
    username: contentforce
    password: <%= ENV["CONTENTFORCE_DATABASE_PASSWORD"] %>
```

**Стало (правильно):**
```yaml
production:
  url: <%= ENV.fetch("DATABASE_URL") { "" } %>
```

### Шаг 2: Закоммитьте изменения

```bash
cd /Users/avdemkin/Documents/документы/CONTtg/contentforce

git add config/database.yml
git commit -m "Fix production database config to use DATABASE_URL"
git push origin main
```

### Шаг 3: Настройте DATABASE_URL в Coolify

1. Откройте **Coolify** → Ваше приложение
2. Перейдите в **Environment Variables**
3. Найдите или добавьте `DATABASE_URL`

**Правильные настройки:**

```env
# Имя переменной
DATABASE_URL

# Значение (используйте postgresql://)
postgresql://postgres:tyVAGamoOg3sl3hMABKBybW9oZ2uIBxJvKIhRXMuCX5tod772H1z1mqPyAsrj5rt@qcwkg0w4ssscks44o48c0k8w:5432/postgres

# КРИТИЧНО: Отметьте галочки
✅ Runtime: ВКЛЮЧЕНО
❌ Build Time: ВЫКЛЮЧЕНО
```

### Шаг 4: Удалите старую переменную (если есть)

Если у вас есть `CONTENTFORCE_DATABASE_PASSWORD`, удалите её - она больше не нужна.

### Шаг 5: Передеплойте приложение

1. В Coolify нажмите **Deploy**
2. Дождитесь окончания build
3. Проверьте логи

## 📋 Полный чеклист переменных для Coolify

### Обязательные Runtime переменные:

```env
DATABASE_URL=postgresql://postgres:tyVAGamoOg3sl3hMABKBybW9oZ2uIBxJvKIhRXMuCX5tod772H1z1mqPyAsrj5rt@qcwkg0w4ssscks44o48c0k8w:5432/postgres
REDIS_URL=redis://[имя-redis-сервиса]:6379/0
RAILS_MASTER_KEY=995a2f3b6ea26667605e7b925ed0b195
SECRET_KEY_BASE=7e8e8025083082bbeedda51f96cbda612bb96183538db25a276dca485c2f0ba7df59cbebfbbca7fbb4fefc8d882c20cdc0fb1d1044de9e1fe00af6191a45a121
TELEGRAM_BOT_TOKEN=7608089982:AAGx-Z4oG6qVIbqlva2Wwbt39nqNSZAi4YU
OPENROUTER_API_KEY=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
```

### Build Time + Runtime (можно оба):

```env
RAILS_ENV=production
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
OPENROUTER_API_URL=https://openrouter.ai/api/v1
OPENROUTER_SITE_URL=https://ваш-домен.com
OPENROUTER_SITE_NAME=ContentForce
TELEGRAM_ORIGIN_URL=https://ваш-домен.com
```

## 🔍 Как проверить что всё работает

### После деплоя проверьте логи:

Ищите эти строки (успех):

```
=> Booting Puma
=> Rails 8.0.4 application starting in production
Puma starting in single mode...
* Listening on http://0.0.0.0:3000
```

### Если видите ошибку подключения:

```bash
# В Coolify Terminal выполните:
echo $DATABASE_URL
```

Должно вывести:
```
postgresql://postgres:tyVAGamoOg3sl3hMABKBybW9oZ2uIBxJvKIhRXMuCX5tod772H1z1mqPyAsrj5rt@qcwkg0w4ssscks44o48c0k8w:5432/postgres
```

Если пусто или неправильно → переменная не установлена как Runtime!

### Проверка подключения к базе:

```bash
# В Coolify Terminal
./bin/rails runner "puts ActiveRecord::Base.connection.active?"
```

Должно вывести: `true`

## 🎯 Важные моменты

### ✅ Правильный формат DATABASE_URL:

```
postgresql://username:password@host:port/database
```

### ❌ Неправильные форматы:

```
# Неправильно - дубликат postgres://
postgres://postgres:postgres://...

# Неправильно - старый префикс
postgres://postgres:password@...

# Правильно
postgresql://postgres:password@...
```

### ✅ Имя хоста:

В Coolify используйте **Internal Service Name**, не `localhost`!

```
# Правильно
postgresql://...@qcwkg0w4ssscks44o48c0k8w:5432/...

# Неправильно
postgresql://...@localhost:5432/...
```

## 🚀 Следующие шаги после исправления

1. ✅ Закоммитьте изменения database.yml
2. ✅ Настройте DATABASE_URL как Runtime в Coolify
3. ✅ Удалите CONTENTFORCE_DATABASE_PASSWORD (не нужна)
4. ✅ Передеплойте приложение
5. ✅ Проверьте логи
6. ✅ Откройте приложение в браузере

## ❓ FAQ

**Q: Нужно ли удалять старые миграции cache/queue/cable?**

A: Нет, они не мешают. Rails будет использовать только primary базу данных.

**Q: Что если у меня несколько баз данных?**

A: Для простого деплоя одна база достаточна. Solid Queue/Cache/Cable работают в той же базе.

**Q: Можно ли использовать postgres:// вместо postgresql://?**

A: Лучше использовать `postgresql://` - это современный стандарт и избегает путаницы.

---

## ✅ После выполнения всех шагов

Деплой должен пройти успешно и приложение запустится!

Проверьте: `https://ваш-домен.com/up` → должен вернуть 200 OK
