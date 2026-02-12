# Floating Sponsor Banner

Плавающий рекламный баннер в правом нижнем углу страницы с настройками через админ-панель.

## Возможности

- ✅ Фиксированная позиция в правом нижнем углу
- ✅ Тёмная тема (zinc-900) с border и скруглёнными углами
- ✅ Загрузка иконки/логотипа (PNG, JPG, WEBP, SVG)
- ✅ Жёлтый бейдж "Спонсор"
- ✅ Кликабельная карточка с внешней ссылкой
- ✅ Кнопка закрытия (×)
- ✅ Сохранение состояния в localStorage (не показывать повторно после закрытия)
- ✅ Плавная анимация появления (fade in + slide up)
- ✅ z-index: 50 (поверх контента)
- ✅ Выбор места отображения: публичные страницы ИЛИ личный кабинет
- ✅ НЕ показывается на мини-сайтах (channel sites)
- ✅ Singleton pattern (один активный баннер на каждое место отображения)

## Использование

### 1. Запуск миграции

```bash
rails db:migrate
```

### 2. Создание баннера в админке

1. Перейдите в админ-панель: `/admin/sponsor_banners`
2. Нажмите "Создать баннер"
3. Заполните поля:
   - **Заголовок** (обязательно, макс. 100 символов)
   - **Описание** (опционально, макс. 200 символов)
   - **Ссылка** (обязательно, валидный URL)
   - **Где показывать** (выбор между "Публичные страницы" и "Личный кабинет")
   - **Иконка/Логотип** (опционально, макс. 1MB)
   - **Включить баннер** (checkbox для активации)
4. Сохраните

### 3. Управление баннерами

- Только один баннер может быть активен для каждого места отображения (публичные страницы / личный кабинет)
- При активации нового баннера, предыдущий с тем же `display_on` автоматически отключается
- Можно иметь одновременно 2 активных баннера: один для публичных страниц, другой для dashboard
- Баннер НЕ показывается на мини-сайтах (channel sites)
- Пользователи, закрывшие баннер, не увидят его повторно (сохраняется в localStorage)

## Технические детали

### Модель: `SponsorBanner`

```ruby
# Атрибуты
title       :string   # Заголовок
description :text     # Описание
url         :string   # Ссылка
enabled     :boolean  # Активен ли баннер
display_on  :integer  # Где показывать: 0 = public_pages, 1 = dashboard
icon        :attachment # Active Storage (PNG, JPG, WEBP, SVG)

# Enum
display_on: { public_pages: 0, dashboard: 1 }

# Методы
SponsorBanner.current(:public_pages)  # Возвращает активный баннер для публичных страниц
SponsorBanner.current(:dashboard)     # Возвращает активный баннер для dashboard
SponsorBanner.current                 # По умолчанию :public_pages
```

### Stimulus Controller: `sponsor_banner_controller.js`

```javascript
// Очистка истории закрытых баннеров (для отладки в консоли)
window.SponsorBannerController.clearHistory()
```

### Файлы

- **Модель**: `app/models/sponsor_banner.rb`
- **Контроллер**: `app/controllers/admin/sponsor_banners_controller.rb`
- **Views**: `app/views/admin/sponsor_banners/`
- **Partial**: `app/views/shared/_sponsor_banner.html.erb`
- **Stimulus**: `app/javascript/controllers/sponsor_banner_controller.js`
- **Миграция**: `db/migrate/XXXXXX_create_sponsor_banners.rb`

## Примеры использования

### Создание баннера для публичных страниц

```ruby
SponsorBanner.create!(
  title: "ContentForce Pro",
  description: "Профессиональный инструмент для автоматизации контента",
  url: "https://contentforce.ru",
  display_on: :public_pages,
  enabled: true
)
```

### Создание баннера для личного кабинета

```ruby
SponsorBanner.create!(
  title: "Upgrade to Pro",
  description: "Получите больше возможностей с Pro версией",
  url: "https://contentforce.ru/pricing",
  display_on: :dashboard,
  enabled: true
)
```

### С иконкой

```ruby
banner = SponsorBanner.create!(
  title: "Наш спонсор",
  description: "Поддерживают проект",
  url: "https://example.com",
  display_on: :public_pages,
  enabled: true
)

banner.icon.attach(
  io: File.open("path/to/logo.png"),
  filename: "logo.png",
  content_type: "image/png"
)
```

## Стилизация

Баннер использует Tailwind CSS классы:
- `bg-zinc-900` - тёмный фон
- `border-zinc-700` - border
- `rounded-xl` - скруглённые углы
- `shadow-2xl` - тень
- `z-50` - поверх контента
- Анимация через Stimulus controller

## Очистка localStorage (для тестирования)

В консоли браузера:
```javascript
localStorage.removeItem('closedSponsorBanners')
```

Или через Stimulus:
```javascript
window.SponsorBannerController.clearHistory()
```

## Тестирование

```bash
# Запуск тестов модели
rspec spec/models/sponsor_banner_spec.rb

# Все тесты
rspec
```

## Безопасность

- ✅ URL валидация (только http/https)
- ✅ Content-type валидация для иконок
- ✅ Ограничение размера файла (1MB)
- ✅ Strong Parameters в контроллере
- ✅ Sanitized output в views
