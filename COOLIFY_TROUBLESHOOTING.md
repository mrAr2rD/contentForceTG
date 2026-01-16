# Coolify Deployment Troubleshooting

## Критические ошибки и их исправление

### ⚠️ ОШИБКА 1: Неправильный формат DATABASE_URL

**Проблема:**
```env
# НЕПРАВИЛЬНО - двойной postgres:// и кириллица
DATABASE_URL=postgres://postgres:postgres://postgres:contForce_v2@log0c0ckws40gkgwkgsks4sg:5432/postgresс
```

**Решение:**
```env
# ПРАВИЛЬНО
DATABASE_URL=postgresql://postgres:contForce_v2@postgres-service-name:5432/postgres
```

**Формат DATABASE_URL:**
```
postgresql://[username]:[password]@[host]:[port]/[database]
```

**Как получить правильный DATABASE_URL в Coolify:**

1. Зайдите в Coolify → Ваше приложение → Resources
2. Найдите PostgreSQL сервис
3. Скопируйте Internal Connection String
4. Замените `postgres-service-name` на фактическое имя сервиса из Coolify

### ⚠️ ОШИБКА 2: Неправильные имена сервисов

**Проблема:**
```env
DATABASE_URL=postgresql://postgres:password@postgres:5432/postgres
REDIS_URL=redis://redis:6379/0
```

В Coolify сервисы имеют уникальные имена, не просто `postgres` или `redis`!

**Решение:**

1. В Coolify перейдите в раздел Resources
2. Найдите название PostgreSQL сервиса (например: `postgres-contentforce-xyz123`)
3. Найдите название Redis сервиса (например: `redis-contentforce-abc456`)
4. Используйте эти имена в URL:

```env
DATABASE_URL=postgresql://postgres:password@postgres-contentforce-xyz123:5432/postgres
REDIS_URL=redis://redis-contentforce-abc456:6379/0
```

### ⚠️ ОШИБКА 3: Переменные установлены как Build-time вместо Runtime

**Проблема:**
Секретные ключи установлены как build-time переменные и попадают в Docker image.

**Решение:**

В Coolify → Environment Variables:

**Отметьте как RUNTIME ONLY:**
- ✅ `DATABASE_URL` - Runtime Only
- ✅ `REDIS_URL` - Runtime Only
- ✅ `RAILS_MASTER_KEY` - Runtime Only
- ✅ `SECRET_KEY_BASE` - Runtime Only
- ✅ `TELEGRAM_BOT_TOKEN` - Runtime Only
- ✅ `OPENROUTER_API_KEY` - Runtime Only

**Можно оставить Build-time:**
- `RAILS_ENV=production`
- `RAILS_LOG_TO_STDOUT=true`
- `RAILS_SERVE_STATIC_FILES=true`

### ⚠️ ОШИБКА 4: Порт не совпадает

**Проблема:**
```
Dockerfile: EXPOSE 3000
Coolify: Port Mapping 80 → 3000
```

**Решение в Coolify:**

1. Settings → Network
2. Port Mappings:
   - **Container Port:** `3000` (из Dockerfile)
   - **Public Port:** `80` или `443`

### ⚠️ ОШИБКА 5: Assets не загружаются

**Симптомы:**
- Страница открывается, но без CSS
- В консоли браузера ошибки 404 на `/assets/...`

**Решение:**

Проверьте переменные окружения:
```env
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

Пересоберите assets:
```bash
# В Coolify Terminal
./bin/rails assets:precompile RAILS_ENV=production
```

### ⚠️ ОШИБКА 6: Database not found

**Ошибка:**
```
PG::ConnectionBad: database "postgres" does not exist
```

**Решение:**

Создайте базу данных вручную:

```bash
# В Coolify Terminal для приложения
./bin/rails db:create RAILS_ENV=production
./bin/rails db:migrate RAILS_ENV=production
```

Или одной командой:
```bash
./bin/rails db:prepare RAILS_ENV=production
```

### ⚠️ ОШИБКА 7: Missing RAILS_MASTER_KEY

**Ошибка:**
```
Missing encryption key to decrypt file with. Ask your team for your master key and write it to config/master.key
```

**Решение:**

На локальной машине:
```bash
cd contentforce
cat config/master.key
```

Скопируйте значение и добавьте в Coolify:
```env
RAILS_MASTER_KEY=значение_из_config_master_key
```

Отметьте как **Runtime Only**!

### ⚠️ ОШИБКА 8: Health check failing

**Проблема:**
Health check endpoint `/up` не отвечает.

**Решение:**

1. В Coolify → Settings → Health Check:
   - Path: `/up`
   - Port: `3000` (внутренний порт контейнера)
   - Interval: `30s`
   - Timeout: `10s`
   - Retries: `3`

2. Проверьте, что роут существует:
```bash
# В терминале Coolify
./bin/rails routes | grep health
```

Должно быть:
```
GET /up rails/health#show
```

### ⚠️ ОШИБКА 9: Build fails at assets:precompile

**Ошибка:**
```
rake aborted!
Sprockets::Rails::Helper::AssetNotPrecompiled
```

**Решение:**

Dockerfile уже содержит правильную команду:
```dockerfile
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
```

Если ошибка все еще есть, проверьте:

1. Все файлы закоммичены в git
2. `package.json` и `yarn.lock` присутствуют
3. Node.js версия совместима

### ⚠️ ОШИБКА 10: Connection refused (Redis)

**Ошибка:**
```
Redis::CannotConnectError: Error connecting to Redis on redis:6379
```

**Решение:**

1. Убедитесь, что Redis сервис создан в Coolify
2. Проверьте REDIS_URL:

```bash
# В Coolify Terminal
echo $REDIS_URL
```

Должно быть:
```
redis://[redis-service-name]:6379/0
```

3. Замените имя сервиса на фактическое из Coolify Resources

## Пошаговая проверка после деплоя

### Шаг 1: Проверка переменных окружения

```bash
# В Coolify Terminal
env | grep -E "(DATABASE_URL|REDIS_URL|RAILS_ENV|RAILS_MASTER_KEY)"
```

Должно вывести все необходимые переменные.

### Шаг 2: Проверка подключения к БД

```bash
# В Coolify Terminal
./bin/rails runner "puts ActiveRecord::Base.connection.active?"
```

Должно вывести: `true`

### Шаг 3: Проверка миграций

```bash
./bin/rails db:migrate:status
```

Все миграции должны быть `up`.

### Шаг 4: Проверка Redis

```bash
./bin/rails runner "puts Rails.cache.write('test', 'ok') && Rails.cache.read('test')"
```

Должно вывести: `ok`

### Шаг 5: Проверка assets

Откройте в браузере:
```
https://your-domain.com/assets/application-[hash].css
```

Должен загрузиться CSS файл.

### Шаг 6: Проверка health check

```bash
curl http://localhost:3000/up
```

Должно вернуть: `OK` или 200 status

## Логи для диагностики

### Production logs
```bash
# В Coolify Terminal
tail -f log/production.log
```

### Build logs
В Coolify UI: Deployments → Latest → Build Logs

### Container logs
В Coolify UI: Container Logs (real-time)

## Быстрое исправление DATABASE_URL

Если у вас сейчас неправильный DATABASE_URL:

**Текущий (неправильный):**
```env
DATABASE_URL=postgres://postgres:postgres://postgres:contForce_v2@log0c0ckws40gkgwkgsks4sg:5432/postgresс
```

**Исправленный:**
```env
DATABASE_URL=postgresql://postgres:contForce_v2@log0c0ckws40gkgwkgsks4sg:5432/postgres
```

**Важно:**
1. Убрали дубликат `postgres://`
2. Изменили `postgres://` на `postgresql://`
3. Исправили кириллицу `postgresс` → `postgres`
4. Проверьте, что `log0c0ckws40gkgwkgsks4sg` - это правильное имя сервиса в Coolify

## Полный чеклист перед деплоем

- [ ] `DATABASE_URL` в правильном формате без дубликатов
- [ ] `DATABASE_URL` содержит правильное имя PostgreSQL сервиса из Coolify
- [ ] `REDIS_URL` содержит правильное имя Redis сервиса из Coolify
- [ ] `RAILS_MASTER_KEY` установлен и отмечен как Runtime Only
- [ ] `SECRET_KEY_BASE` установлен и отмечен как Runtime Only
- [ ] Все секретные переменные отмечены как Runtime Only
- [ ] Port mapping: Container `3000` → Public `80`
- [ ] Health check настроен на `/up` порт `3000`
- [ ] PostgreSQL сервис создан и запущен
- [ ] Redis сервис создан и запущен
- [ ] Все файлы закоммичены в git

## Тест локально перед деплоем

Соберите Docker image локально:

```bash
cd contentforce

# Build image
docker build -t contentforce-test .

# Run with env vars
docker run --rm -it \
  -e DATABASE_URL="postgresql://postgres:postgres@host.docker.internal:5432/contentforce_test" \
  -e RAILS_MASTER_KEY="$(cat config/master.key)" \
  -e SECRET_KEY_BASE="test_secret" \
  -e RAILS_ENV=production \
  -p 3000:3000 \
  contentforce-test
```

Если локально работает, значит проблема в конфигурации Coolify.

## Контакты поддержки

Если ничего не помогает:
1. Экспортируйте логи из Coolify
2. Проверьте форум Coolify: https://coolify.io/docs
3. Создайте issue с логами

---

**Самые частые причины проблем:**
1. ❌ Неправильный формат DATABASE_URL (60% случаев)
2. ❌ Неправильные имена сервисов в URL (20% случаев)
3. ❌ Секреты установлены как Build-time (10% случаев)
4. ❌ Отсутствует RAILS_MASTER_KEY (5% случаев)
5. ❌ Неправильный Port Mapping (5% случаев)
