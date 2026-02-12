# Отладка проблемы с Robokassa

## Что было сделано

### 1. Добавлено ручное управление платежами в админке

**Контроллер:** `app/controllers/admin/payments_controller.rb`
- Метод `confirm` — ручное подтверждение платежа и активация подписки
- Метод `cancel` — отмена платежа

**UI:** `app/views/admin/payments/show.html.erb` и `index.html.erb`
- Кнопки "Подтвердить платёж" и "Отменить" для pending/failed платежей
- Кнопки быстрого действия (✓/✕) в таблице платежей

### 2. Исправлен баг в webhook

**Файл:** `app/controllers/webhooks/robokassa_controller.rb`

**Проблема:** При успешной оплате не обновлялся `plan_record` (связь с таблицей plans)

**Исправление:**
```ruby
plan_slug = payment.metadata['plan']
plan_record = Plan.cached_find_by_slug(plan_slug) || Plan.find_by_slug(plan_slug)

subscription.update!(
  plan: plan_slug,
  plan_record: plan_record,  # ← Добавлено!
  status: :active,
  current_period_start: Time.current,
  current_period_end: 1.month.from_now
)
```

### 3. Добавлено подробное логирование

Теперь webhook логирует:
- Все входящие параметры от Robokassa
- Ошибки валидации подписи
- Успешные активации подписок

---

## Проверка на проде

### Шаг 1: Проверить настройки в Robokassa

Войдите в личный кабинет Robokassa и проверьте URL'ы:

1. **Result URL (технический):** `https://contentforce.ru/webhooks/robokassa/result`
2. **Success URL (редирект при успехе):** `https://contentforce.ru/webhooks/robokassa/success`
3. **Fail URL (редирект при ошибке):** `https://contentforce.ru/webhooks/robokassa/fail`

### Шаг 2: Проверить логи на проде

```bash
# Подключитесь к серверу и проверьте логи
tail -f log/production.log | grep -i robokassa

# Ищите такие строки:
# - "Robokassa Result URL called with params: ..."
# - "Robokassa signature validation failed..."
# - "Payment ... processed successfully"
```

### Шаг 3: Проверить пароли Robokassa в админке

1. Зайдите в админку: `https://contentforce.ru/admin/payment_settings/edit`
2. Убедитесь, что заполнены:
   - Merchant Login
   - Password #1 (для формирования подписи при оплате)
   - Password #2 (для проверки подписи от Result URL)
3. Пароли должны совпадать с теми, что в личном кабинете Robokassa

### Шаг 4: Ручное подтверждение проблемного платежа

1. Зайдите в админку: `https://contentforce.ru/admin/payments`
2. Найдите платёж со статусом "В обработке" (pending)
3. Нажмите "Просмотр"
4. Нажмите кнопку "Подтвердить платёж"

Подписка будет активирована вручную.

---

## Возможные причины проблемы

### 1. Result URL не настроен или неправильный
**Решение:** Проверьте настройки в Robokassa (Шаг 1)

### 2. Неправильная проверка подписи
**Причина:** Password #2 не совпадает с тем, что в Robokassa

**Как проверить:**
```bash
# В логах будет:
# "Robokassa signature validation failed. OutSum: 2.0, InvId: 20260212466182, Signature: ..."
```

**Решение:** Обновите Password #2 в админке

### 3. Result URL не вызывается из-за firewall
**Проверка:**
```bash
# Проверьте, приходят ли запросы на /webhooks/robokassa/result
grep "webhooks/robokassa/result" log/production.log
```

**Решение:** Убедитесь, что IP адреса Robokassa не заблокированы

### 4. Тестовый режим включён, но Result URL вызывается только в боевом
**Проверка:** В админке `payment_settings` посмотрите флаг `test_mode`

**Решение:** Убедитесь, что Result URL настроен и для тестового режима в Robokassa

---

## Тестирование после деплоя

### 1. Сделайте тестовую оплату
- Зайдите на страницу тарифов
- Выберите любой платный тариф (2₽ в тестовом режиме)
- Оплатите через Robokassa

### 2. Проверьте логи сразу после оплаты
```bash
tail -100 log/production.log | grep -i robokassa
```

### 3. Если Result URL не вызвался
- Подтвердите платёж вручную через админку
- Проверьте настройки Result URL в Robokassa

---

## Деплой на прод

```bash
git add -A
git commit -m "fix: добавлено ручное управление платежами и улучшено логирование webhook

- Добавлены методы confirm/cancel для ручного управления платежами
- Исправлен баг с plan_record в webhook
- Добавлено подробное логирование для отладки
- Обновлён UI админки для pending/failed платежей"
git push origin dev
```

После деплоя Coolify автоматически применит изменения.
