# 🚀 Руководство по запуску ContentForce

## Обновлено: 15 января 2026

### ✨ Что нового

- ✅ **Этап 3 завершен** - AI интеграция полностью готова
- ✅ **Notion-style UI** - весь интерфейс переработан
- ✅ **Темная тема** - автоматическое переключение
- ✅ **ViewComponent** - компонентная архитектура

---

## 📋 Быстрый старт

### 1. Запустить базу данных

```bash
cd contentforce
docker-compose up -d db redis
```

**Результат:** PostgreSQL и Redis запущены в фоне

---

### 2. Установить зависимости

```bash
# Ruby gems
bundle install

# JavaScript packages
yarn install
# или
npm install
```

**Время:** ~2-3 минуты

---

### 3. Выполнить миграции

```bash
rails db:create
rails db:migrate
```

**Новые миграции:**
- `20260115133856_create_ai_configurations.rb` - настройки AI
- `20260115133924_create_ai_usage_logs.rb` - логи использования AI

**Всего миграций:** 9

---

### 4. Создать тестовые данные (опционально)

```bash
rails db:seed
```

---

### 5. Запустить приложение

```bash
bin/dev
```

**Запускается:**
- Rails server (port 3000)
- Tailwind CSS watcher
- esbuild для JavaScript
- Solid Queue workers

**Приложение доступно:** http://localhost:3000

---

## 🎨 Новый интерфейс

### Темная тема

Переключение темы:
- **Кнопка** в sidebar (иконка луны)
- **Автоматически** определяет системную тему
- **Сохраняется** в localStorage

### Компоненты

Доступны ViewComponent компоненты:

```erb
<!-- Button -->
<%= render Ui::ButtonComponent.new(variant: :default, size: :md) do %>
  Нажми меня
<% end %>

<!-- Card -->
<%= render Ui::CardComponent.new do |card| %>
  <% card.with_header do %>
    <h3>Заголовок</h3>
  <% end %>
  Содержимое карточки
<% end %>

<!-- Input -->
<%= render Ui::InputComponent.new(name: "email", type: "email", placeholder: "Email") %>

<!-- Sidebar -->
<%= render Ui::SidebarComponent.new do |sidebar| %>
  <% sidebar.with_item(label: "Dashboard", href: dashboard_path, icon: "📊", active: true) %>
<% end %>
```

---

## 🔧 Конфигурация

### Переменные окружения

Создайте `.env` файл:

```bash
cp .env.example .env
```

**Обязательные переменные:**

```bash
# Database
DATABASE_URL=postgresql://localhost/contentforce_development

# OpenRouter AI
OPENROUTER_API_KEY=your_api_key
OPENROUTER_SITE_URL=http://localhost:3000
OPENROUTER_SITE_NAME=ContentForce

# Telegram Bot
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_BOT_USERNAME=your_bot_username
```

---

## 📊 Структура проекта

### Новые файлы

```
contentforce/
├── app/
│   ├── components/          # ✨ НОВОЕ - ViewComponents
│   │   ├── ui/
│   │   │   ├── button_component.rb
│   │   │   ├── card_component.rb
│   │   │   ├── input_component.rb
│   │   │   └── sidebar_component.rb
│   │   └── layouts/
│   ├── models/
│   │   ├── ai_configuration.rb    # ✨ НОВОЕ
│   │   └── ai_usage_log.rb        # ✨ НОВОЕ
│   └── javascript/
│       └── controllers/
│           └── theme_controller.js # ✨ НОВОЕ
├── lib/
│   └── openrouter/
│       └── client.rb              # ✨ НОВОЕ
└── db/
    └── migrate/
        ├── 20260115133856_create_ai_configurations.rb  # ✨ НОВОЕ
        └── 20260115133924_create_ai_usage_logs.rb      # ✨ НОВОЕ
```

---

## 🎯 Основные функции

### 1. AI Генерация контента

```ruby
# В консоли Rails
generator = Ai::ContentGenerator.new(project: project, user: user)
result = generator.generate(prompt: "Напиши пост про AI")

# result[:content] - сгенерированный текст
# result[:model_used] - использованная модель
# result[:tokens_used] - потраченные токены
```

### 2. Настройка AI

```ruby
# Глобальные настройки
config = AiConfiguration.current
config.update(
  default_model: 'claude-3-sonnet',
  temperature: 0.8,
  max_tokens: 3000
)

# Настройки проекта
project.update(ai_model: 'gpt-4-turbo')
```

### 3. Трекинг использования

```ruby
# Статистика пользователя
AiUsageLog.total_cost_for_user(user, 30.days)

# Популярные модели
AiUsageLog.popular_models(5)

# Использование по целям
AiUsageLog.usage_by_purpose
```

---

## 🧪 Тестирование

### Запуск тестов

```bash
# Все тесты
rspec

# Конкретная модель
rspec spec/models/ai_configuration_spec.rb

# С покрытием кода
COVERAGE=true rspec
```

---

## 🐛 Troubleshooting

### База данных не подключается

```bash
# Проверить статус контейнеров
docker-compose ps

# Перезапустить
docker-compose restart db

# Логи
docker-compose logs db
```

### Миграции не выполняются

```bash
# Проверить статус
rails db:migrate:status

# Откатить последнюю
rails db:rollback

# Пересоздать БД
rails db:drop db:create db:migrate
```

### Tailwind CSS не компилируется

```bash
# Пересобрать CSS
npm run build:css

# Или через bin/dev (автоматически)
bin/dev
```

### ViewComponent не работает

```bash
# Убедитесь что gem установлен
bundle list | grep view_component

# Переустановить
bundle install
```

---

## 📚 Дополнительные ресурсы

- [ROADMAP.md](ROADMAP.md) - план разработки
- [PRD.md](PRD.md) - требования к продукту
- [CHANGELOG.md](CHANGELOG.md) - список изменений
- [README_ДЕПЛОЙ.md](README_ДЕПЛОЙ.md) - инструкции по деплою

---

## ✅ Чеклист перед запуском

- [ ] PostgreSQL и Redis запущены
- [ ] `.env` файл создан и заполнен
- [ ] `bundle install` выполнен
- [ ] `yarn install` выполнен
- [ ] `rails db:migrate` выполнен
- [ ] `bin/dev` запущен
- [ ] Приложение открывается на http://localhost:3000
- [ ] Темная тема переключается
- [ ] AI генерация работает (нужен OPENROUTER_API_KEY)

---

## 🎉 Готово!

Приложение готово к разработке. Откройте http://localhost:3000 и наслаждайтесь новым Notion-style интерфейсом!

**Следующие шаги:**
1. Зарегистрируйтесь через Telegram или Email
2. Создайте первый проект
3. Попробуйте AI редактор
4. Переключите темную тему

---

**Версия:** 0.3.0  
**Дата:** 15 января 2026  
**Статус:** ✅ Готово к разработке
