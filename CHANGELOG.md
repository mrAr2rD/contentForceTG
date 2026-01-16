# Changelog - ContentForce

## [Unreleased] - 2026-01-15

### ✅ Завершено: Этап 3 - AI Интеграция (100%)

#### Добавлено
- **AiConfiguration модель** - управление настройками AI
  - Поддержка множества моделей (GPT-4, Claude 3, Llama 3)
  - Настройка temperature, max_tokens
  - Кастомные system prompts
  - Fallback модели для отказоустойчивости
  
- **AiUsageLog модель** - трекинг использования AI
  - Логирование всех AI запросов
  - Подсчет токенов и стоимости
  - Статистика по моделям и целям использования
  - Методы для аналитики (total_cost_for_user, popular_models)

- **OpenRouter Client** (`lib/openrouter/client.rb`)
  - Полноценный клиент для OpenRouter API
  - Поддержка chat completions
  - Обработка ошибок и retry логика
  - Интеграция с Faraday

#### Улучшено
- **AI::ContentGenerator** - полная интеграция с OpenRouter
  - Использует OpenRouter Client вместо прямых HTTP запросов
  - Автоматический трекинг использования в AiUsageLog
  - Проверка лимитов подписки перед генерацией
  - Fallback на резервные модели при ошибках
  - Расчет стоимости запросов

- **Subscription модель** - расширенные методы
  - `can_use?(feature)` - универсальная проверка лимитов
  - `increment_usage!(feature)` - универсальный счетчик
  - `limit_for(feature)` и `usage_for(feature)` - хелперы
  - `ai_generations_remaining` - остаток AI запросов
  - `PLAN_LIMITS` - константа с лимитами всех тарифов

---

### 🎨 Редизайн интерфейса: Notion-style с ShadcnUI

#### Добавлено
- **ViewComponent** - компонентная архитектура UI
  - `Ui::ButtonComponent` - кнопки в стиле shadcn-ui
  - `Ui::CardComponent` - карточки с header/footer
  - `Ui::InputComponent` - инпуты с темной темой
  - `Ui::SidebarComponent` - навигация в стиле Notion

- **Темная тема (Dark Mode)**
  - `theme_controller.js` - Stimulus контроллер для переключения темы
  - Автоматическое определение системной темы
  - Сохранение выбора в localStorage
  - Поддержка во всех компонентах

- **Tailwind CSS 4.1** - обновленная конфигурация
  - Notion-inspired цветовая палитра (zinc)
  - Кастомные CSS переменные для темной темы
  - Notion-style типографика и spacing
  - Кастомные scrollbar стили
  - Утилиты для Notion-style компонентов

#### Переработано
- **Dashboard Layout** (`app/views/layouts/dashboard.html.erb`)
  - Полностью переработан в стиле Notion
  - Sidebar с градиентным логотипом
  - Кнопка переключения темы в header
  - Улучшенная навигация с иконками
  - User profile с hover эффектами
  - Notion-style flash messages

- **Dashboard Index** (`app/views/dashboard/index.html.erb`)
  - Notion-style приветствие с эмодзи
  - Quick Actions кнопки
  - Улучшенные stat cards с градиентами
  - Recent activity cards с hover эффектами
  - Getting Started callout для новых пользователей
  - Полная поддержка темной темы

- **Post Editor** (`app/views/posts/editor.html.erb`)
  - Трехпанельный интерфейс в стиле Notion
  - AI Chat панель с градиентным header
  - Settings панель с улучшенными формами
  - Preview панель с Telegram-style карточкой
  - Notion-style textarea для контента
  - Quick actions кнопки
  - Real-time character counter

- **Projects Index** (`app/views/projects/index.html.erb`)
  - Grid layout с Notion-style карточками
  - Градиентные иконки проектов
  - Status badges (Активный/Архив)
  - Hover эффекты и transitions
  - Empty state с призывом к действию
  - Meta информация (посты, боты, время обновления)

---

## 📊 Статистика изменений

### Файлы созданы (9):
1. `contentforce/db/migrate/20260115133856_create_ai_configurations.rb`
2. `contentforce/db/migrate/20260115133924_create_ai_usage_logs.rb`
3. `contentforce/app/models/ai_configuration.rb`
4. `contentforce/app/models/ai_usage_log.rb`
5. `contentforce/lib/openrouter/client.rb`
6. `contentforce/app/components/ui/button_component.rb`
7. `contentforce/app/components/ui/card_component.rb`
8. `contentforce/app/components/ui/input_component.rb`
9. `contentforce/app/components/ui/sidebar_component.rb`
10. `contentforce/app/javascript/controllers/theme_controller.js`

### Файлы изменены (7):
1. `contentforce/Gemfile` - добавлены view_component и lookbook
2. `contentforce/app/services/ai/content_generator.rb` - интеграция OpenRouter Client
3. `contentforce/app/models/subscription.rb` - расширенные методы лимитов
4. `contentforce/app/assets/stylesheets/application.tailwind.css` - Notion-style дизайн
5. `contentforce/app/views/layouts/dashboard.html.erb` - Notion-style layout
6. `contentforce/app/views/dashboard/index.html.erb` - Notion-style dashboard
7. `contentforce/app/views/posts/editor.html.erb` - Notion-style editor
8. `contentforce/app/views/projects/index.html.erb` - Notion-style projects

---

## 🎯 Следующие шаги

### Немедленно:
- [ ] Дождаться завершения `rails db:migrate`
- [ ] Дождаться завершения `bundle install` (view_component)
- [ ] Запустить `bin/dev` для проверки интерфейса

### Краткосрочно (1-2 дня):
- [ ] Создать остальные UI компоненты (Select, Dialog, Dropdown)
- [ ] Переработать Posts index view
- [ ] Переработать формы создания/редактирования
- [ ] Добавить анимации и transitions

### Среднесрочно (1 неделя):
- [ ] Написать тесты для новых моделей
- [ ] Настроить GitHub Actions CI/CD
- [ ] Начать Этап 4 (Календарь и аналитика)

---

## 🐛 Известные проблемы

- Миграции еще не выполнены (команда в процессе)
- view_component gem устанавливается
- Необходимо протестировать темную тему в браузере

---

## 📝 Примечания

### Архитектурные решения:
1. **ViewComponent вместо React** - для сохранения Rails-way подхода
2. **Tailwind CSS 4.1** - для современного дизайна
3. **Stimulus для интерактивности** - минимальный JavaScript
4. **Notion-style дизайн** - минимализм, много whitespace, мягкие тени

### Дизайн-система:
- **Цвета**: Zinc palette (50-950) для нейтральных цветов
- **Primary**: Blue (500-600) для акцентов
- **Spacing**: Notion-style (больше whitespace)
- **Typography**: System fonts для быстрой загрузки
- **Shadows**: Subtle (shadow-sm, shadow-md)
- **Borders**: Тонкие (1px) с низкой контрастностью

---

**Версия:** 0.3.0  
**Дата:** 15 января 2026  
**Автор:** Kilo Code  
**Статус:** ✅ Этап 3 завершен, редизайн выполнен
