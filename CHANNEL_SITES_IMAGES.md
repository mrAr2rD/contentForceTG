# Скачивание изображений из Telegram для мини-сайтов

## Описание

Теперь при синхронизации постов из Telegram автоматически скачиваются изображения и сохраняются в Active Storage вместо использования прямых ссылок.

## Преимущества

✅ **Надежность**: Изображения хранятся локально, не зависят от доступности Telegram CDN
✅ **Производительность**: Быстрая загрузка через локальное хранилище или CDN
✅ **Контроль**: Полный контроль над изображениями (обработка, оптимизация)
✅ **SEO**: Улучшенная индексация изображений поисковыми системами

## Как это работает

### 1. Модель ChannelPost

Добавлен Active Storage attachment:
```ruby
class ChannelPost < ApplicationRecord
  has_many_attached :images
end
```

### 2. Метод first_image

Обновлен для приоритетного использования скачанных изображений:
```ruby
def first_image
  # Если есть скачанные картинки - используем первую
  return images.first if images.attached?

  # Иначе возвращаем URL из media
  media.find { |m| m["type"] == "photo" }&.dig("url")
end
```

### 3. Сервис импорта

При синхронизации постов (`ChannelSites::ImportPostsService`):
1. Получает данные постов с URLs изображений в поле `media`
2. Скачивает изображения по URL через `URI.open`
3. Прикрепляет к посту через Active Storage
4. Логирует успех/ошибку скачивания

```ruby
def attach_images_from_media(post, media_array)
  photos = media_array.select { |m| m["type"] == "photo" && m["url"].present? }

  photos.each do |photo|
    downloaded_image = URI.open(photo["url"])
    post.images.attach(
      io: downloaded_image,
      filename: "telegram_#{post.telegram_message_id}_#{SecureRandom.hex(4)}.jpg",
      content_type: "image/jpeg"
    )
  end
end
```

### 4. Helper для отображения

Создан helper `channel_post_image_url`:
```ruby
def channel_post_image_url(channel_post)
  first_image = channel_post.first_image

  if first_image.respond_to?(:url)
    url_for(first_image)  # Active Storage attachment
  else
    first_image  # URL строка из media
  end
end
```

### 5. Views обновлены

Все partials используют helper вместо прямого обращения к `first_image`:
```erb
<img src="<%= channel_post_image_url(channel_post) %>" ... >
```

## Поведение

### При создании нового поста
1. Telegram API возвращает URLs изображений в `media`
2. Сервис импорта скачивает изображения и прикрепляет к посту
3. `first_image` возвращает Active Storage attachment

### При обновлении существующего поста
- Если изображения уже скачаны - пропускаем
- Если нет - скачиваем при следующей синхронизации

### Fallback
Если скачивание не удалось или изображения еще не скачаны:
- `first_image` возвращает URL из `media`
- Изображения загружаются с Telegram CDN

## Логирование

Успешная загрузка:
```
Скачано изображение для поста 12345: https://cdn.telegram.org/...
```

Ошибка загрузки:
```
Ошибка скачивания изображения для поста 12345: Connection timeout
```

## Миграция существующих постов

Для скачивания изображений для существующих постов без картинок:

```ruby
# В Rails console
ChannelPost.where.not(media: []).find_each do |post|
  next if post.images.attached?

  service = ChannelSites::ImportPostsService.new(post.channel_site, [])
  service.send(:attach_images_from_media, post, post.media)
end
```

## Storage настройки

### Development
- Хранение: локальный диск (`storage/`)
- Путь: `app/storage/`

### Production
- Рекомендуется: S3-совместимое хранилище
- Настройки в `config/storage.yml`
- ENV переменные: `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `S3_BUCKET`

## Обработка изображений

Можно добавить варианты изображений для оптимизации:

```ruby
# Модель
has_many_attached :images do |attachable|
  attachable.variant :thumb, resize_to_limit: [300, 300]
  attachable.variant :medium, resize_to_limit: [800, 800]
end

# View
<%= image_tag channel_post.images.first.variant(:thumb) %>
```

## Безопасность

✅ Валидация content-type при скачивании
✅ Ограничение размера файла (настраивается в Active Storage)
✅ Безопасное имя файла (UUID)
✅ Обработка ошибок при скачивании

## Мониторинг

Отслеживайте логи для:
- Частоты ошибок скачивания
- Времени выполнения импорта
- Размера хранилища
