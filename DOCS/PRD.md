# Product Requirements Document (PRD)
# ContentForce - AI-помощник для управления контентом в соцсетях

**Версия:** 1.1  
**Дата:** 10 января 2026  
**Статус:** Ready for Development  
**Repository:** contentForceTG

---

## Содержание

1. [Обзор продукта](#1-обзор-продукта)
2. [Функциональные требования](#2-функциональные-требования)
3. [Технические требования](#3-технические-требования)
4. [Дизайн и UX](#4-дизайн-и-ux)
5. [Пользовательские сценарии](#5-пользовательские-сценарии)
6. [Аналитика и метрики](#6-аналитика-и-метрики)
7. [Тестирование](#7-тестирование)
8. [Развертывание и инфраструктура](#8-развертывание-и-инфраструктура)
9. [Roadmap и приоритеты](#9-roadmap-и-приоритеты)
10. [Риски и митигация](#10-риски-и-митигация)
11. [Метрики успеха](#11-метрики-успеха)
12. [Поддержка и документация](#12-поддержка-и-документация)
13. [Compliance и Legal](#13-compliance-и-legal)
14. [Приложения](#14-приложения)

---

## 1. Обзор продукта

### 1.1 Название продукта
**ContentForce** - микро-SaaS платформа для автоматизации создания и публикации контента в Telegram и социальных сетях с использованием искусственного интеллекта.

### 1.2 Видение продукта
ContentForce упрощает процесс создания и публикации контента для владельцев Telegram-каналов и соцсетей, предоставляя интуитивный интерфейс с AI-ассистентом для генерации постов, автоматическую публикацию через ботов и удобное планирование контента.

### 1.3 Целевая аудитория
- Владельцы и администраторы Telegram-каналов
- SMM-специалисты и контент-менеджеры
- Малый и средний бизнес
- Блогеры и инфлюенсеры
- Digital-агентства
- Соло-предприниматели

### 1.4 Проблемы, которые решает продукт
- Трудоемкость создания качественного контента
- Отсутствие единого интерфейса для управления несколькими каналами
- Необходимость постоянного присутствия для публикации постов
- Сложность поддержания единого tone of voice
- Высокая стоимость найма копирайтеров

---

## 2. Функциональные требования

### 2.1 Аутентификация и регистрация

#### 2.1.1 Регистрация через Telegram
**Приоритет:** Высокий

**Функционал:**
- Использование Telegram Login Widget
- Получение базовой информации: ID, username, имя, фото профиля
- Автоматическое создание учетной записи
- Редирект на онбординг после первой регистрации

**Технические детали:**
```ruby
# app/models/user.rb
class User < ApplicationRecord
  # Telegram authentication
  def self.from_telegram_auth(auth_data)
    user = find_or_initialize_by(telegram_id: auth_data['id'])
    user.assign_attributes(
      telegram_username: auth_data['username'],
      first_name: auth_data['first_name'],
      last_name: auth_data['last_name'],
      avatar_url: auth_data['photo_url']
    )
    user.save!
    user
  end
end
```

#### 2.1.2 Регистрация через Email
**Приоритет:** Высокий

**Функционал:**
- Стандартная форма: email, пароль, подтверждение пароля
- Email-верификация через ссылку активации
- Возможность восстановления пароля
- Валидация email и требования к паролю (минимум 8 символов)

**Технические детали:**
```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, if: :password_required?
end
```

#### 2.1.3 Управление сессиями
- Поддержка "Запомнить меня" (30 дней)
- Возможность выхода из всех устройств
- Просмотр активных сессий

---

### 2.2 Управление проектами

#### 2.2.1 Создание проекта
**Приоритет:** Высокий

**Поля:**
- Название проекта (обязательное)
- Описание проекта
- Логотип/аватар проекта (опционально)
- Категория (Бизнес, Блог, Новости, Развлечения, Образование и др.)
- Настройки по умолчанию (tone of voice, стиль, язык)
- AI модель (выбор из доступных в OpenRouter)

**Модель:**
```ruby
# app/models/project.rb
class Project < ApplicationRecord
  belongs_to :user
  has_many :telegram_bots, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_one_attached :logo

  enum category: {
    business: 0,
    blog: 1,
    news: 2,
    entertainment: 3,
    education: 4,
    technology: 5,
    health: 6,
    other: 99
  }

  enum default_tone_of_voice: {
    friendly: 0,
    professional: 1,
    enthusiastic: 2,
    formal: 3,
    casual: 4,
    emotional: 5,
    informational: 6,
    sales: 7
  }

  validates :name, presence: true, length: { maximum: 100 }
  validates :category, presence: true

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archive!
    update(archived_at: Time.current)
  end

  def unarchive!
    update(archived_at: nil)
  end
end
```

#### 2.2.2 Подключение Telegram-бота
**Приоритет:** Критический

**Процесс подключения:**
1. Создание бота через @BotFather
2. Получение API токена
3. Добавление токена в ContentForce
4. Верификация бота (проверка валидности токена)
5. Добавление бота в целевой канал/группу как администратора
6. Проверка прав бота (публикация сообщений)
7. Настройка webhook
8. Сохранение конфигурации

**Требуемые права для бота:**
- Публикация сообщений
- Редактирование сообщений
- Удаление сообщений

**Модель:**
```ruby
# app/models/telegram_bot.rb
class TelegramBot < ApplicationRecord
  belongs_to :project
  has_many :posts, dependent: :nullify
  has_many :subscriber_metrics, class_name: 'ChannelSubscriberMetrics', dependent: :destroy

  encrypts :bot_token

  enum chat_type: { channel: 0, group: 1, supergroup: 2 }
  enum status: { active: 0, inactive: 1, error: 2 }

  validates :bot_token, presence: true
  validates :bot_username, uniqueness: true, allow_nil: true

  after_create :verify_bot
  after_create :setup_webhook

  def verify_bot
    service = Telegram::VerifyService.new(self)
    service.verify!
  rescue => e
    update(status: :error, error_message: e.message)
  end

  def setup_webhook
    service = Telegram::WebhookService.new(self)
    service.setup!
  end

  def telegram_client
    @telegram_client ||= Telegram::Bot::Client.new(bot_token)
  end
end
```

**Сервис верификации:**
```ruby
# app/services/telegram/verify_service.rb
module Telegram
  class VerifyService
    def initialize(telegram_bot)
      @bot = telegram_bot
      @client = telegram_bot.telegram_client
    end

    def verify!
      # 1. Проверяем токен
      bot_info = @client.get_me
      @bot.update!(
        bot_username: bot_info.username,
        verified_at: Time.current,
        status: :active
      )

      # 2. Проверяем права в чате (если chat_id указан)
      if @bot.chat_id.present?
        verify_chat_permissions
      end

      true
    rescue Telegram::Bot::Exceptions::ResponseError => e
      @bot.update!(
        status: :error,
        error_message: "Invalid token: #{e.message}"
      )
      raise
    end

    private

    def verify_chat_permissions
      chat_member = @client.get_chat_member(
        chat_id: @bot.chat_id,
        user_id: @client.get_me.id
      )

      unless can_post_messages?(chat_member)
        raise "Bot doesn't have permission to post messages"
      end

      @bot.update!(
        chat_title: get_chat_title,
        chat_type: determine_chat_type
      )
    end

    def can_post_messages?(chat_member)
      chat_member.can_post_messages == true ||
        chat_member.status == 'administrator'
    end

    def get_chat_title
      chat = @client.get_chat(chat_id: @bot.chat_id)
      chat.title
    end

    def determine_chat_type
      chat = @client.get_chat(chat_id: @bot.chat_id)
      case chat.type
      when 'channel' then :channel
      when 'group' then :group
      when 'supergroup' then :supergroup
      end
    end
  end
end
```

#### 2.2.3 Подключение других соцсетей (будущая функциональность)
**Приоритет:** Средний
- VK
- Instagram (через Facebook API)
- Facebook
- Twitter/X

---

### 2.3 Интерфейс создания контента

#### 2.3.1 Трехпанельная компоновка
**Приоритет:** Критический

**Структура экрана:**
```
┌─────────────────────────────────────────────────────────────┐
│  Шапка: Проект | Кнопка публикации | Статус                 │
├──────────────┬────────────────────┬──────────────────────────┤
│              │                    │                          │
│   AI-чат     │    Настройки       │    Превью поста         │
│   (слева)    │    (центр)         │    (справа)             │
│              │                    │                          │
│   30%        │      20%           │       50%               │
│              │                    │                          │
└──────────────┴────────────────────┴──────────────────────────┘
```

**Технические детали (Stimulus Controller):**
```javascript
// app/javascript/controllers/post_editor_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "chatInput", 
    "chatMessages", 
    "preview", 
    "settingsPanel"
  ]
  static values = {
    projectId: String,
    botId: String
  }

  connect() {
    this.initializeWebSocket()
  }

  async sendMessage(event) {
    event.preventDefault()
    const message = this.chatInputTarget.value
    
    // Добавляем сообщение пользователя
    this.appendMessage('user', message)
    
    // Очищаем input
    this.chatInputTarget.value = ''
    
    // Показываем индикатор загрузки
    this.showLoadingIndicator()
    
    try {
      // Отправляем запрос к AI
      const response = await fetch('/api/v1/ai/generate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          prompt: message,
          project_id: this.projectIdValue,
          context: this.getCurrentContext()
        })
      })
      
      const data = await response.json()
      
      // Добавляем ответ AI
      this.appendMessage('assistant', data.content)
      
      // Обновляем превью
      this.updatePreview(data.content)
      
    } catch (error) {
      console.error('AI generation error:', error)
      this.showError('Ошибка при генерации контента')
    } finally {
      this.hideLoadingIndicator()
    }
  }

  updatePreview(content) {
    this.previewTarget.innerHTML = this.formatMarkdown(content)
  }

  formatMarkdown(text) {
    // Простое форматирование Telegram markdown
    return text
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.*?)\*/g, '<em>$1</em>')
      .replace(/`(.*?)`/g, '<code>$1</code>')
      .replace(/\[(.*?)\]\((.*?)\)/g, '<a href="$2">$1</a>')
      .replace(/\n/g, '<br>')
  }

  // ... остальные методы
}
```

#### 2.3.2 Левая панель: AI-чат интерфейс
**Приоритет:** Критический

**Функционал:**
- Чат-интерфейс в стиле ChatGPT
- История диалога в рамках создания одного поста
- Возможность редактирования предыдущих сообщений
- Кнопки быстрых действий:
  - "Сгенерировать пост"
  - "Улучшить текст"
  - "Сделать короче/длиннее"
  - "Изменить tone of voice"
  - "Добавить эмодзи"
  - "Добавить хештеги"
  - "Сгенерировать изображение"

**Примеры промптов:**
- "Напиши пост о новом продукте с акцентом на выгоды"
- "Создай мотивационный пост для утра"
- "Напиши анонс вебинара в дружелюбном тоне"

**AI через OpenRouter:**
```ruby
# app/services/ai/content_generator.rb
class AI::ContentGenerator
  def initialize(project: nil, user: nil)
    @project = project
    @user = user
    @config = AiConfiguration.current
  end
  
  def generate(prompt:, context: {})
    # Проверка лимитов тарифа
    unless can_generate?
      raise AI::LimitExceededError, 'AI generation limit exceeded for current plan'
    end
    
    # Получаем модель из настроек проекта или глобальных настроек
    model = @project&.ai_model || @config.default_model
    
    # Строим системный промпт с контекстом проекта
    system_prompt = build_system_prompt(context)
    
    # Вызов OpenRouter API
    response = call_openrouter(
      model: model,
      system: system_prompt,
      user_message: prompt,
      temperature: @config.temperature,
      max_tokens: @config.max_tokens
    )
    
    # Трекинг использования
    track_usage(response)
    
    response[:content]
  rescue OpenRouter::APIError => e
    handle_api_error(e, prompt, context)
  end
  
  private
  
  def call_openrouter(model:, system:, user_message:, temperature:, max_tokens:)
    client = OpenRouter::Client.new
    
    response = client.chat(
      model: model,
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user_message }
      ],
      temperature: temperature,
      max_tokens: max_tokens,
      transforms: ['middle-out'],
      route: 'fallback'
    )
    
    {
      content: response['choices'][0]['message']['content'],
      model_used: response['model'],
      tokens_used: response['usage']['total_tokens'],
      cost: calculate_cost(response)
    }
  end
  
  def build_system_prompt(context)
    base_prompt = @config.custom_system_prompt || default_system_prompt
    
    if @project
      base_prompt += "\n\nПроект: #{@project.name}"
      base_prompt += "\nТон голоса: #{@project.default_tone_of_voice}"
      base_prompt += "\nОписание: #{@project.description}" if @project.description
    end
    
    if context[:previous_posts]
      base_prompt += "\n\nПримеры предыдущих постов:\n"
      context[:previous_posts].each do |post|
        base_prompt += "- #{post.content[0..200]}\n"
      end
    end
    
    base_prompt
  end
  
  def default_system_prompt
    <<~PROMPT
      Ты - профессиональный копирайтер и SMM-специалист для Telegram-каналов.
      Твоя задача - создавать привлекательный, вовлекающий контент для социальных сетей.
      
      Правила:
      - Пиши живым, естественным языком
      - Используй эмодзи умеренно и к месту
      - Структурируй текст для легкого чтения
      - Добавляй призывы к действию там, где уместно
      - Адаптируй тон под указанный стиль проекта
      - Длина поста: оптимально 300-800 символов, максимум 4000
      
      Форматирование Telegram markdown:
      - **жирный текст**
      - *курсив*
      - `код`
      - [ссылка](url)
    PROMPT
  end
  
  def handle_api_error(error, prompt, context)
    Rails.logger.error("OpenRouter API Error: #{error.message}")
    
    fallback_models = @config.fallback_models || ['gpt-3.5-turbo']
    
    fallback_models.each do |fallback_model|
      begin
        return call_openrouter(
          model: fallback_model,
          system: build_system_prompt(context),
          user_message: prompt,
          temperature: @config.temperature,
          max_tokens: @config.max_tokens
        )
      rescue => e
        next
      end
    end
    
    raise AI::GenerationError, 'All AI models failed. Please try again later.'
  end
  
  def track_usage(response)
    AiUsageLog.create!(
      user: @user,
      project: @project,
      model_used: response[:model_used],
      tokens_used: response[:tokens_used],
      cost: response[:cost],
      purpose: 'content_generation'
    )
    
    if @user.subscription
      @user.subscription.increment_ai_usage!
    end
  end
  
  def can_generate?
    return true unless @user.subscription
    @user.subscription.ai_generations_remaining > 0
  end
  
  def calculate_cost(response)
    model_info = AiConfiguration::AVAILABLE_MODELS[response['model']]
    return 0 unless model_info
    
    input_tokens = response['usage']['prompt_tokens']
    output_tokens = response['usage']['completion_tokens']
    
    input_cost = (input_tokens / 1000.0) * model_info[:cost_per_1k_tokens][:input]
    output_cost = (output_tokens / 1000.0) * model_info[:cost_per_1k_tokens][:output]
    
    input_cost + output_cost
  end
end
```

#### 2.3.3 Центральная панель: Настройки публикации
**Приоритет:** Высокий

**Блоки настроек:**

**1. Стиль и тон (Tone of Voice)**
- Дружелюбный
- Профессиональный
- Энтузиазм
- Формальный
- Непринужденный
- Эмоциональный
- Информационный
- Продающий

**2. Формат поста**
- Простой текст
- Текст с изображением
- Текст с изображением и кнопкой
- Карусель (будущая функция)
- Видео (будущая функция)

**3. Настройки изображения** (если выбран формат с изображением)
- Загрузка собственного изображения (drag & drop)
- Генерация через AI (DALL-E)
- Библиотека стоковых изображений (Unsplash API)
- Редактор изображений (кадрирование, фильтры)

**4. Настройки кнопки** (если выбран формат с кнопкой)
- Текст кнопки (макс. 64 символа)
- URL ссылки
- Тип кнопки (обычная ссылка, callback)

**5. Планирование**
- Опубликовать сейчас
- Отложенная публикация (выбор даты и времени)
- Добавить в очередь публикаций

**6. Дополнительные опции**
- Отключить уведомления (silent mode)
- Защита контента (запрет пересылки)
- Режим предпросмотра ссылок

#### 2.3.4 Правая панель: Превью поста
**Приоритет:** Высокий

**Функционал:**
- Реалтайм превью поста в стиле Telegram
- Отображение текста с markdown-форматированием
- Превью изображения (если добавлено)
- Отображение кнопки (если добавлена)
- Счетчик символов и лимиты (Telegram: 4096 символов)
- Возможность прямого редактирования текста

---

### 2.4 Календарь публикаций

#### 2.4.1 Представление календаря
**Приоритет:** Высокий

**Виды отображения:**
- Месяц (по умолчанию)
- Неделя
- День
- Список

**Функционал:**
- Drag & drop для переноса постов
- Цветовая кодировка по статусам:
  - Запланировано (синий)
  - Опубликовано (зеленый)
  - Черновик (серый)
  - Ошибка публикации (красный)
- Быстрый просмотр поста по клику
- Фильтры по проектам, статусу, типу контента, каналам

**Технические детали:**
```ruby
# app/controllers/calendar_controller.rb
class CalendarController < ApplicationController
  def index
    @posts = current_user.posts
      .includes(:project, :telegram_bot)
      .where(project_id: filter_params[:project_ids])
      .where('scheduled_at BETWEEN ? AND ?', start_date, end_date)
      .order(:scheduled_at)
  end

  def update_schedule
    post = current_user.posts.find(params[:id])
    
    if post.update(scheduled_at: params[:scheduled_at])
      # Обновляем job в очереди
      post.reschedule_publication!
      
      render json: { success: true, post: post }
    else
      render json: { success: false, errors: post.errors }, status: :unprocessable_entity
    end
  end
end
```

#### 2.4.2 Управление отложенными постами
**Приоритет:** Высокий

**Модель:**
```ruby
# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :project
  belongs_to :telegram_bot
  belongs_to :user
  has_one_attached :image

  enum post_type: { text: 0, image: 1, image_button: 2 }
  enum status: { draft: 0, scheduled: 1, published: 2, failed: 3 }
  enum tone_of_voice: {
    friendly: 0, professional: 1, enthusiastic: 2,
    formal: 3, casual: 4, emotional: 5,
    informational: 6, sales: 7
  }

  validates :content, presence: true, length: { maximum: 4096 }
  validates :button_text, length: { maximum: 64 }, if: -> { post_type == 'image_button' }
  validates :button_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), 
            if: -> { button_url.present? }

  after_create :schedule_publication, if: -> { scheduled? && scheduled_at.present? }
  
  def schedule_publication!
    PublishPostJob.set(wait_until: scheduled_at).perform_later(id)
  end

  def reschedule_publication!
    # Отменяем старую задачу и создаем новую
    # Solid Queue автоматически управляет этим
    schedule_publication!
  end

  def publish!
    Telegram::PublishService.new(self).publish!
  end
end
```

**Background Job:**
```ruby
# app/jobs/publish_post_job.rb
class PublishPostJob < ApplicationJob
  queue_as :default
  retry_on Telegram::Bot::Exceptions::ResponseError, wait: :exponentially_longer, attempts: 3

  def perform(post_id)
    post = Post.find(post_id)
    
    # Проверяем что пост еще нужно публиковать
    return unless post.scheduled?
    
    # Публикуем
    result = post.publish!
    
    # Обновляем статус
    post.update!(
      status: :published,
      published_at: Time.current,
      telegram_message_id: result.message_id
    )
    
    # Запускаем сбор аналитики
    Analytics::UpdatePostViewsJob.perform_later(post.telegram_bot_id)
    
  rescue => e
    post.update!(
      status: :failed,
      error_message: e.message
    )
    
    # Уведомляем пользователя
    NotificationService.notify_publication_failed(post.user, post, e)
    
    raise
  end
end
```

#### 2.4.3 Очередь публикаций
**Приоритет:** Средний

- Автоматическое распределение постов по времени
- Настройка интервалов публикации
- Оптимальное время публикации (на основе аналитики)

---

### 2.5 Библиотека контента

#### 2.5.1 Управление черновиками
**Приоритет:** Высокий

**Модель:**
```ruby
# app/models/post_draft.rb
class PostDraft < ApplicationRecord
  belongs_to :project
  belongs_to :user

  validates :title, length: { maximum: 200 }
  
  # Автосохранение через Action Cable
  after_update_commit -> { broadcast_update }

  def broadcast_update
    broadcast_replace_to(
      [project, "drafts"],
      partial: "drafts/draft",
      locals: { draft: self }
    )
  end
end
```

#### 2.5.2 История публикаций
**Приоритет:** Средний

- Архив всех опубликованных постов
- Статистика по каждому посту
- Поиск по истории
- Повторная публикация старых постов
- Экспорт истории

#### 2.5.3 Шаблоны постов
**Приоритет:** Средний

**Модель:**
```ruby
# app/models/template.rb
class Template < ApplicationRecord
  belongs_to :project, optional: true
  
  enum category: {
    announcement: 0, promotion: 1, motivational: 2,
    news: 3, educational: 4, engagement: 5
  }

  validates :name, presence: true
  validates :content, presence: true

  scope :public_templates, -> { where(is_public: true) }
  scope :project_templates, ->(project) { where(project: project) }
end
```

---

### 2.6 Расширенная аналитика (для платных тарифов)

#### 2.6.1 Собираемые метрики

**1. Просмотры постов**
```ruby
# app/models/post_analytics.rb
class PostAnalytics < ApplicationRecord
  belongs_to :post

  validates :date, presence: true, uniqueness: { scope: :post_id }
end
```

**2. Клики и взаимодействия**
```ruby
# app/models/button_click_event.rb
class ButtonClickEvent < ApplicationRecord
  belongs_to :post

  # Анонимизированный ID пользователя
  validates :user_telegram_id, presence: true
end
```

**3. Подписчики (рост и отток)**
```ruby
# app/models/channel_subscriber_metrics.rb
class ChannelSubscriberMetrics < ApplicationRecord
  belongs_to :telegram_bot

  validates :date, presence: true, uniqueness: { scope: :telegram_bot_id }
  
  def growth_rate
    return 0 if total_subscribers.zero?
    (net_growth.to_f / total_subscribers * 100).round(2)
  end
end
```

**4. Button Click Tracking с URL shortener**
```ruby
# app/models/tracked_link.rb
class TrackedLink < ApplicationRecord
  belongs_to :post
  has_many :click_events, class_name: 'ButtonClickEvent'

  before_create :generate_tracking_id

  def short_url
    "#{ENV['APP_URL']}/t/#{tracking_id}"
  end

  private

  def generate_tracking_id
    self.tracking_id = SecureRandom.urlsafe_base64(8)
  end
end

# app/controllers/tracked_links_controller.rb
class TrackedLinksController < ApplicationController
  skip_before_action :authenticate_user!

  def redirect
    link = TrackedLink.find_by!(tracking_id: params[:id])
    
    # Записываем клик
    ButtonClickEvent.create!(
      post: link.post,
      button_text: link.button_text,
      button_url: link.original_url,
      clicked_at: Time.current,
      user_telegram_id: anonymize_ip(request.remote_ip)
    )
    
    # Редирект
    redirect_to link.original_url, allow_other_host: true
  end

  private

  def anonymize_ip(ip)
    Digest::SHA256.hexdigest(ip + Rails.application.secret_key_base)
  end
end
```

**5. Churn Rate Calculation**
```ruby
# app/services/churn_rate_calculator.rb
class ChurnRateCalculator
  def calculate_for_period(telegram_bot, start_date, end_date)
    metrics = ChannelSubscriberMetrics
      .where(telegram_bot: telegram_bot)
      .where(date: start_date..end_date)
    
    total_at_start = metrics.first.total_subscribers
    total_unsubscribed = metrics.sum(:unsubscribed)
    
    churn_rate = (total_unsubscribed.to_f / total_at_start * 100).round(2)
    
    {
      churn_rate: churn_rate,
      unsubscribed: total_unsubscribed,
      period_start_subscribers: total_at_start,
      period_end_subscribers: metrics.last.total_subscribers
    }
  end
  
  def post_churn_correlation(telegram_bot, days = 30)
    # Посты которые вызвали больше всего отписок
    Post
      .published
      .where(telegram_bot: telegram_bot)
      .where('published_at > ?', days.days.ago)
      .joins(:subscriber_changes)
      .where(subscriber_changes: { change_type: :unsubscribed })
      .group('posts.id')
      .select('posts.*, COUNT(subscriber_changes.id) as unsubscribe_count')
      .order('unsubscribe_count DESC')
  end
end
```

**6. Subscriber Change Tracking**
```ruby
# app/models/subscriber_change.rb
class SubscriberChange < ApplicationRecord
  belongs_to :telegram_bot
  belongs_to :post, optional: true

  enum change_type: { subscribed: 0, unsubscribed: 1 }

  # Время между публикацией поста и отпиской
  def time_since_post_seconds
    return nil unless post && occurred_at && post.published_at
    (occurred_at - post.published_at).to_i
  end
end
```

#### 2.6.2 Webhook для Telegram событий

```ruby
# config/routes.rb
post '/webhooks/telegram/:bot_token', to: 'webhooks/telegram#receive'

# app/controllers/webhooks/telegram_controller.rb
class Webhooks::TelegramController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_bot

  def receive
    update = JSON.parse(request.body.read)
    
    case
    when update['callback_query']
      handle_button_click(update['callback_query'])
    when update['chat_member']
      handle_member_change(update['chat_member'])
    when update['channel_post']
      handle_post_view(update['channel_post'])
    end
    
    head :ok
  end

  private

  def find_bot
    @bot = TelegramBot.find_by(bot_token: params[:bot_token])
    head :not_found unless @bot
  end

  def handle_button_click(callback_query)
    post = Post.find_by(
      telegram_message_id: callback_query['message']['message_id']
    )
    
    return unless post

    ButtonClickEvent.create!(
      post: post,
      button_text: callback_query['message']['reply_markup']['inline_keyboard'].first.first['text'],
      clicked_at: Time.at(callback_query['message']['date']),
      user_telegram_id: hash_user_id(callback_query['from']['id'])
    )
  end

  def handle_member_change(chat_member)
    old_status = chat_member['old_chat_member']['status']
    new_status = chat_member['new_chat_member']['status']
    
    # Подписка
    if left_status?(old_status) && active_status?(new_status)
      record_subscription(chat_member)
    end
    
    # Отписка
    if active_status?(old_status) && left_status?(new_status)
      record_unsubscription(chat_member)
    end
  end

  def record_subscription(chat_member)
    SubscriberChange.create!(
      telegram_bot: @bot,
      change_type: :subscribed,
      user_telegram_id: hash_user_id(chat_member['from']['id']),
      occurred_at: Time.at(chat_member['date'])
    )
    
    Analytics::UpdateSubscriberCountJob.perform_later(@bot.id)
  end

  def record_unsubscription(chat_member)
    recent_post = @bot.posts.published.order(published_at: :desc).first
    
    SubscriberChange.create!(
      telegram_bot: @bot,
      post: recent_post,
      change_type: :unsubscribed,
      user_telegram_id: hash_user_id(chat_member['from']['id']),
      occurred_at: Time.at(chat_member['date']),
      time_since_post: recent_post ? (Time.at(chat_member['date']) - recent_post.published_at).to_i : nil
    )
    
    Analytics::UpdateSubscriberCountJob.perform_later(@bot.id)
  end

  def left_status?(status)
    ['left', 'kicked'].include?(status)
  end

  def active_status?(status)
    ['member', 'administrator'].include?(status)
  end

  def hash_user_id(telegram_id)
    Digest::SHA256.hexdigest("#{telegram_id}#{Rails.application.secret_key_base}")
  end
end
```

#### 2.6.3 Background Jobs для аналитики

```ruby
# app/jobs/analytics/update_post_views_job.rb
class Analytics::UpdatePostViewsJob < ApplicationJob
  queue_as :analytics
  
  def perform(telegram_bot_id)
    bot = TelegramBot.find(telegram_bot_id)
    service = Telegram::AnalyticsService.new(bot)
    
    recent_posts = bot.posts.published
      .where('published_at > ?', 7.days.ago)
    
    recent_posts.each do |post|
      begin
        views = service.fetch_post_views(post.telegram_message_id)
        
        PostAnalytics.find_or_initialize_by(
          post: post,
          date: Date.current
        ).update!(views_count: views)
      rescue => e
        Rails.logger.error("Failed to update views for post #{post.id}: #{e.message}")
      end
    end
  end
end

# app/jobs/analytics/snapshot_channel_metrics_job.rb
class Analytics::SnapshotChannelMetricsJob < ApplicationJob
  queue_as :analytics
  
  def perform(telegram_bot_id)
    bot = TelegramBot.find(telegram_bot_id)
    service = Telegram::AnalyticsService.new(bot)
    
    current_count = service.get_member_count
    
    yesterday_snapshot = ChannelSubscriberMetrics
      .where(telegram_bot: bot, date: Date.yesterday)
      .first
    
    yesterday_count = yesterday_snapshot&.total_subscribers || current_count
    net_growth = current_count - yesterday_count
    
    ChannelSubscriberMetrics.create!(
      telegram_bot: bot,
      date: Date.current,
      total_subscribers: current_count,
      new_subscribers: [net_growth, 0].max,
      unsubscribed: [net_growth * -1, 0].max,
      net_growth: net_growth
    )
  end
end

# app/jobs/analytics/calculate_churn_rate_job.rb
class Analytics::CalculateChurnRateJob < ApplicationJob
  queue_as :analytics
  
  def perform(telegram_bot_id, period = 'weekly')
    bot = TelegramBot.find(telegram_bot_id)
    calculator = ChurnRateCalculator.new
    
    date_range = case period
    when 'daily' then [Date.yesterday, Date.current]
    when 'weekly' then [7.days.ago.to_date, Date.current]
    when 'monthly' then [30.days.ago.to_date, Date.current]
    end
    
    churn_data = calculator.calculate_for_period(bot, *date_range)
    
    ChurnReport.create!(
      telegram_bot: bot,
      period_type: period,
      period_start: date_range[0],
      period_end: date_range[1],
      churn_rate: churn_data[:churn_rate],
      total_unsubscribed: churn_data[:unsubscribed]
    )
    
    # Alert если churn rate высокий
    if churn_data[:churn_rate] > 5.0
      NotificationService.alert_high_churn(
        bot.project.user,
        bot,
        churn_data
      )
    end
  end
end
```

#### 2.6.4 Dashboard аналитики

**API Endpoints:**
```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :projects do
      member do
        get 'analytics/overview'
        get 'analytics/posts'
        get 'analytics/audience'
        get 'analytics/buttons'
      end
    end
    
    resources :posts do
      member do
        get 'analytics'
      end
    end
  end
end

# app/controllers/api/v1/analytics_controller.rb
module Api
  module V1
    class AnalyticsController < BaseController
      before_action :set_project

      def overview
        render json: {
          today: today_metrics,
          chart_data: chart_data_for_period,
          top_posts: top_performing_posts
        }
      end

      def posts
        posts = @project.posts.published
          .includes(:post_analytics)
          .where('published_at >= ?', start_date)
          .order(published_at: :desc)

        render json: posts, each_serializer: PostAnalyticsSerializer
      end

      def audience
        metrics = @project.telegram_bots
          .flat_map(&:subscriber_metrics)
          .where(date: start_date..end_date)
          .group_by(&:date)

        render json: {
          growth_chart: format_growth_chart(metrics),
          churn_rate: calculate_churn_rate,
          projections: calculate_projections(metrics)
        }
      end

      def buttons
        clicks = ButtonClickEvent
          .joins(post: :project)
          .where(posts: { project_id: @project.id })
          .where('clicked_at >= ?', start_date)
          .group(:button_text, :button_url)
          .count

        render json: format_button_stats(clicks)
      end

      private

      def today_metrics
        {
          views: PostAnalytics.where(post: @project.posts, date: Date.current).sum(:views_count),
          new_subscribers: ChannelSubscriberMetrics.where(
            telegram_bot: @project.telegram_bots,
            date: Date.current
          ).sum(:new_subscribers),
          unsubscribes: ChannelSubscriberMetrics.where(
            telegram_bot: @project.telegram_bots,
            date: Date.current
          ).sum(:unsubscribed),
          button_clicks: ButtonClickEvent.where(
            post: @project.posts,
            clicked_at: Date.current.all_day
          ).count
        }
      end

      # ... другие вспомогательные методы
    end
  end
end
```

---

### 2.7 AI через OpenRouter

#### 2.7.1 OpenRouter Client

```ruby
# lib/openrouter/client.rb
module OpenRouter
  class Client
    BASE_URL = 'https://openrouter.ai/api/v1'
    
    def initialize(api_key: nil)
      @api_key = api_key || ENV['OPENROUTER_API_KEY']
    end
    
    def chat(params)
      response = connection.post('/chat/completions') do |req|
        req.body = build_request_body(params).to_json
      end
      
      handle_response(response)
    end
    
    def models
      response = connection.get('/models')
      JSON.parse(response.body)
    end
    
    private
    
    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :json
        f.response :json
        f.response :raise_error
        f.headers['Authorization'] = "Bearer #{@api_key}"
        f.headers['HTTP-Referer'] = ENV['OPENROUTER_SITE_URL']
        f.headers['X-Title'] = ENV['OPENROUTER_SITE_NAME']
      end
    end
    
    def build_request_body(params)
      {
        model: params[:model],
        messages: params[:messages],
        temperature: params[:temperature] || 0.7,
        max_tokens: params[:max_tokens] || 2000,
        top_p: params[:top_p] || 1.0,
        frequency_penalty: params[:frequency_penalty] || 0,
        presence_penalty: params[:presence_penalty] || 0,
        transforms: params[:transforms] || [],
        route: params[:route] || 'fallback'
      }.compact
    end
    
    def handle_response(response)
      body = JSON.parse(response.body)
      
      {
        content: body.dig('choices', 0, 'message', 'content'),
        model: body['model'],
        usage: {
          prompt_tokens: body.dig('usage', 'prompt_tokens'),
          completion_tokens: body.dig('usage', 'completion_tokens'),
          total_tokens: body.dig('usage', 'total_tokens')
        },
        id: body['id'],
        created: body['created']
      }
    rescue => e
      Rails.logger.error("OpenRouter API Error: #{e.message}")
      raise OpenRouter::Error, e.message
    end
  end
  
  class Error < StandardError; end
end
```

#### 2.7.2 AI Configuration Model

```ruby
# app/models/ai_configuration.rb
class AiConfiguration < ApplicationRecord
  # Singleton pattern - только одна конфигурация
  def self.current
    first_or_create!(
      default_model: DEFAULT_MODEL,
      temperature: DEFAULT_TEMPERATURE,
      max_tokens: DEFAULT_MAX_TOKENS
    )
  end

  AVAILABLE_MODELS = {
    'gpt-4-turbo' => {
      name: 'GPT-4 Turbo',
      provider: 'OpenAI',
      context_length: 128000,
      cost_per_1k_tokens: { input: 0.01, output: 0.03 },
      recommended_for: ['Качественный контент', 'Сложные задачи']
    },
    'claude-3-opus' => {
      name: 'Claude 3 Opus',
      provider: 'Anthropic',
      context_length: 200000,
      cost_per_1k_tokens: { input: 0.015, output: 0.075 },
      recommended_for: ['Длинный контент', 'Анализ']
    },
    'claude-3-sonnet' => {
      name: 'Claude 3 Sonnet',
      provider: 'Anthropic',
      context_length: 200000,
      cost_per_1k_tokens: { input: 0.003, output: 0.015 },
      recommended_for: ['Баланс цена/качество', 'Универсальный']
    },
    'claude-3-haiku' => {
      name: 'Claude 3 Haiku',
      provider: 'Anthropic',
      context_length: 200000,
      cost_per_1k_tokens: { input: 0.00025, output: 0.00125 },
      recommended_for: ['Быстрые задачи', 'Экономия']
    },
    'gpt-3.5-turbo' => {
      name: 'GPT-3.5 Turbo',
      provider: 'OpenAI',
      context_length: 16385,
      cost_per_1k_tokens: { input: 0.0005, output: 0.0015 },
      recommended_for: ['Простые задачи', 'Максимальная экономия']
    },
    'llama-3-70b' => {
      name: 'Llama 3 70B',
      provider: 'Meta',
      context_length: 8192,
      cost_per_1k_tokens: { input: 0.0007, output: 0.0009 },
      recommended_for: ['Бюджетный вариант', 'Open source']
    }
  }.freeze

  DEFAULT_MODEL = 'claude-3-sonnet'
  DEFAULT_TEMPERATURE = 0.7
  DEFAULT_MAX_TOKENS = 2000

  validates :default_model, inclusion: { in: AVAILABLE_MODELS.keys }
  validates :temperature, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 2 
  }
  validates :max_tokens, numericality: { 
    greater_than: 0, 
    less_than_or_equal_to: 4000 
  }
end
```

#### 2.7.3 Специализированные AI сервисы

```ruby
# app/services/ai/post_improver.rb
class AI::PostImprover < AI::ContentGenerator
  def improve(text:, improvement_type:)
    prompts = {
      shorten: "Сократи следующий текст, сохранив главную мысль:\n\n#{text}",
      lengthen: "Расширь следующий текст, добавив детали и примеры:\n\n#{text}",
      add_emojis: "Добавь подходящие эмодзи в текст:\n\n#{text}",
      add_hashtags: "Добавь релевантные хэштеги к тексту:\n\n#{text}",
      change_tone: "Перепиши текст в другом tone of voice:\n\n#{text}",
      fix_grammar: "Исправь грамматические ошибки:\n\n#{text}"
    }
    
    generate(prompt: prompts[improvement_type.to_sym])
  end
end

# app/services/ai/image_prompt_generator.rb
class AI::ImagePromptGenerator < AI::ContentGenerator
  def generate_image_prompt(post_content:)
    prompt = <<~PROMPT
      На основе следующего текста поста создай подробный промпт для генерации изображения на английском языке.
      Промпт должен быть детальным, визуальным и подходить для DALL-E или Midjourney.
      
      Текст поста:
      #{post_content}
      
      Верни только промпт для генерации изображения, без дополнительных объяснений.
    PROMPT
    
    generate(prompt: prompt)
  end
end

# app/services/ai/hashtag_generator.rb
class AI::HashtagGenerator < AI::ContentGenerator
  def generate_hashtags(content:, count: 5)
    prompt = <<~PROMPT
      Создай #{count} релевантных хэштегов для следующего поста.
      Хэштеги должны быть на русском языке, популярные и подходящие по теме.
      
      Текст поста:
      #{content}
      
      Верни только хэштеги через пробел, без нумерации и дополнительного текста.
    PROMPT
    
    generate(prompt: prompt)
  end
end
```

#### 2.7.4 AI Usage Tracking

```ruby
# app/models/ai_usage_log.rb
class AiUsageLog < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true

  enum purpose: {
    content_generation: 0,
    content_improvement: 1,
    image_generation: 2,
    hashtag_generation: 3
  }

  # Статистика использования
  def self.total_cost_for_user(user, period = 30.days)
    where(user: user)
      .where('created_at > ?', period.ago)
      .sum(:cost)
  end

  def self.popular_models(limit = 5)
    group(:model_used)
      .order('count_all DESC')
      .limit(limit)
      .count
  end
end
```

---

### 2.8 Админ-панель

#### 2.8.1 Установка Administrate

```ruby
# Gemfile
gem 'administrate'

# Установка
# bundle add administrate
# rails generate administrate:install
```

#### 2.8.2 Dashboard конфигурации

```ruby
# app/dashboards/user_dashboard.rb
require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::String,
    email: Field::String,
    telegram_username: Field::String,
    first_name: Field::String,
    last_name: Field::String,
    role: Field::Select.with_options(
      collection: User.roles.keys
    ),
    subscription: Field::BelongsTo,
    projects: Field::HasMany,
    posts: Field::HasMany.with_options(limit: 5),
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    confirmed_at: Field::DateTime,
    current_sign_in_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    email
    telegram_username
    role
    subscription
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    email
    telegram_username
    first_name
    last_name
    role
    subscription
    projects
    posts
    created_at
    updated_at
    confirmed_at
    current_sign_in_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    email
    first_name
    last_name
    role
  ].freeze

  def display_resource(user)
    user.email
  end
end

# app/dashboards/subscription_dashboard.rb
class SubscriptionDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::String,
    user: Field::BelongsTo,
    plan: Field::Select.with_options(
      collection: Subscription.plans.keys
    ),
    status: Field::Select.with_options(
      collection: Subscription.statuses.keys
    ),
    current_period_start: Field::DateTime,
    current_period_end: Field::DateTime,
    cancel_at_period_end: Field::Boolean,
    canceled_at: Field::DateTime,
    trial_ends_at: Field::DateTime,
    usage: Field::Text,
    limits: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    user
    plan
    status
    current_period_end
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    user
    plan
    status
    current_period_start
    current_period_end
    cancel_at_period_end
    canceled_at
    trial_ends_at
    usage
    limits
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    user
    plan
    status
    current_period_end
    trial_ends_at
  ].freeze
end

# app/dashboards/ai_configuration_dashboard.rb
class AiConfigurationDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::String,
    default_model: Field::Select.with_options(
      collection: AiConfiguration::AVAILABLE_MODELS.keys
    ),
    fallback_models: Field::String,
    temperature: Field::Number.with_options(decimals: 2),
    max_tokens: Field::Number,
    custom_system_prompt: Field::Text,
    enabled_features: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    default_model
    temperature
    max_tokens
    updated_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    default_model
    fallback_models
    temperature
    max_tokens
    custom_system_prompt
    enabled_features
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    default_model
    fallback_models
    temperature
    max_tokens
    custom_system_prompt
    enabled_features
  ].freeze
end
```

#### 2.8.3 Admin Controllers

```ruby
# app/controllers/admin/application_controller.rb
module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_admin

    def authenticate_admin
      unless current_user&.admin?
        redirect_to root_path, alert: 'Access denied'
      end
    end
  end
end

# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < Admin::ApplicationController
    def impersonate
      user = User.find(params[:id])
      sign_in(user)
      redirect_to root_path, notice: "Signed in as #{user.email}"
    end
    
    def reset_limits
      user = User.find(params[:id])
      user.subscription&.reset_usage!
      redirect_to admin_user_path(user), notice: 'Limits reset successfully'
    end
    
    def extend_trial
      user = User.find(params[:id])
      user.subscription&.update(trial_ends_at: 30.days.from_now)
      redirect_to admin_user_path(user), notice: 'Trial extended by 30 days'
    end
  end
end

# app/controllers/admin/dashboard_controller.rb
module Admin
  class DashboardController < Admin::ApplicationController
    def index
      @stats = {
        total_users: User.count,
        active_users: User.where('current_sign_in_at > ?', 7.days.ago).count,
        paying_users: Subscription.active.where.not(plan: 'free').count,
        total_posts: Post.count,
        posts_today: Post.where('created_at >= ?', Date.current).count,
        mrr: calculate_mrr,
        churn_rate: calculate_churn_rate
      }
    end

    private

    def calculate_mrr
      plan_prices = {
        'starter' => 590,
        'pro' => 1490,
        'business' => 2990
      }
      
      Subscription.active.where.not(plan: 'free')
        .sum { |sub| plan_prices[sub.plan] || 0 }
    end

    def calculate_churn_rate
      canceled = Subscription
        .where('canceled_at BETWEEN ? AND ?', 1.month.ago, Time.current)
        .count
      
      active_start = Subscription.active
        .where('created_at < ?', 1.month.ago)
        .count
      
      return 0 if active_start.zero?
      
      (canceled.to_f / active_start * 100).round(2)
    end
  end
end
```

#### 2.8.4 Admin Routes

```ruby
# config/routes.rb
namespace :admin do
  root to: 'dashboard#index'
  
  resources :users do
    member do
      post :impersonate
      post :reset_limits
      post :extend_trial
    end
  end
  
  resources :subscriptions
  resources :projects
  resources :posts
  resources :telegram_bots
  resources :ai_configurations do
    member do
      post :test_model
    end
  end
  resources :payments
  
  get 'analytics', to: 'analytics#index'
  get 'system_health', to: 'system#health'
end
```

---

### 2.9 Тарифы и биллинг

#### 2.9.1 Тарифные планы

**Free (Бесплатный)**
- 1 проект
- 1 Telegram-канал
- 10 постов/месяц
- 5 AI-генераций/месяц
- Базовая аналитика

**Starter (590₽/месяц)**
- 3 проекта
- 3 Telegram-канала
- 100 постов/месяц
- 50 AI-генераций/месяц
- Календарь публикаций
- Полная аналитика (просмотры, клики, подписчики)
- Отслеживание churn rate
- Шаблоны постов
- Email поддержка

**Pro (1490₽/месяц)**
- 10 проектов
- 10 каналов
- Неограниченно постов
- 500 AI-генераций/месяц
- AI-генерация изображений (20/месяц)
- Расширенная аналитика и инсайты
- Командная работа (до 3 участников)
- API доступ
- Приоритетная поддержка

**Business (2990₽/месяц)**
- Неограниченно проектов и каналов
- Неограниченно AI-генераций
- AI-генерация изображений (100/месяц)
- Полная аналитика и прогнозирование
- Командная работа (до 10 участников)
- Белый лейбл
- Персональный менеджер
- SLA 99.9%

**Модель:**
```ruby
# app/models/subscription.rb
class Subscription < ApplicationRecord
  belongs_to :user
  has_many :payments

  enum plan: {
    free: 0,
    starter: 1,
    pro: 2,
    business: 3
  }

  enum status: {
    active: 0,
    canceled: 1,
    past_due: 2,
    unpaid: 3
  }

  PLAN_LIMITS = {
    free: {
      projects: 1,
      bots: 1,
      posts_per_month: 10,
      ai_generations_per_month: 5,
      analytics: :basic
    },
    starter: {
      projects: 3,
      bots: 3,
      posts_per_month: 100,
      ai_generations_per_month: 50,
      analytics: :full
    },
    pro: {
      projects: 10,
      bots: 10,
      posts_per_month: Float::INFINITY,
      ai_generations_per_month: 500,
      ai_image_generations_per_month: 20,
      analytics: :advanced
    },
    business: {
      projects: Float::INFINITY,
      bots: Float::INFINITY,
      posts_per_month: Float::INFINITY,
      ai_generations_per_month: Float::INFINITY,
      ai_image_generations_per_month: 100,
      analytics: :premium
    }
  }.freeze

  def limit_for(feature)
    PLAN_LIMITS.dig(plan.to_sym, feature) || 0
  end

  def usage_for(feature)
    usage.dig(feature.to_s) || 0
  end

  def can_use?(feature, amount = 1)
    limit = limit_for(feature)
    return true if limit == Float::INFINITY
    
    usage_for(feature) + amount <= limit
  end

  def increment_usage!(feature, amount = 1)
    current_usage = usage_for(feature)
    self.usage ||= {}
    self.usage[feature.to_s] = current_usage + amount
    save!
  end

  def reset_usage!
    self.usage = {}
    save!
  end

  def ai_generations_remaining
    limit = limit_for(:ai_generations_per_month)
    return Float::INFINITY if limit == Float::INFINITY
    
    [limit - usage_for(:ai_generations_per_month), 0].max
  end
end
```

#### 2.9.2 Интеграция Robokassa

```ruby
# app/services/payment/robokassa_service.rb
module Payment
  class RobokassaService
    MERCHANT_LOGIN = ENV['ROBOKASSA_LOGIN']
    PASSWORD_1 = ENV['ROBOKASSA_PASSWORD_1']
    PASSWORD_2 = ENV['ROBOKASSA_PASSWORD_2']
    TEST_MODE = ENV['ROBOKASSA_TEST_MODE'] == 'true'

    def initialize(user, plan)
      @user = user
      @plan = plan
    end

    def generate_payment_url
      amount = plan_price(@plan)
      invoice_id = generate_invoice_id
      
      # Создаем платеж в БД
      payment = Payment.create!(
        user: @user,
        amount: amount,
        currency: 'RUB',
        status: :pending,
        provider: :robokassa,
        invoice_id: invoice_id,
        description: "Подписка #{@plan}"
      )

      signature = calculate_signature(
        MERCHANT_LOGIN,
        amount,
        invoice_id,
        PASSWORD_1
      )

      base_url = TEST_MODE ? 'https://auth.robokassa.ru/Merchant/Index.aspx' : 
                             'https://auth.robokassa.ru/Merchant/Index.aspx'

      params = {
        MerchantLogin: MERCHANT_LOGIN,
        OutSum: amount,
        InvId: invoice_id,
        Description: "Подписка ContentForce - #{@plan}",
        SignatureValue: signature,
        IsTest: TEST_MODE ? 1 : 0,
        Email: @user.email,
        Culture: 'ru'
      }

      "#{base_url}?#{params.to_query}"
    end

    def verify_result_signature(params)
      signature = calculate_signature(
        params[:OutSum],
        params[:InvId],
        PASSWORD_2
      )
      
      signature == params[:SignatureValue]
    end

    def process_payment_result(params)
      return false unless verify_result_signature(params)

      payment = Payment.find_by(invoice_id: params[:InvId])
      return false unless payment

      ActiveRecord::Base.transaction do
        payment.update!(
          status: :completed,
          provider_payment_id: params[:PaymentMethod],
          paid_at: Time.current
        )

        # Активируем или обновляем подписку
        activate_subscription(payment)
      end

      true
    rescue => e
      Rails.logger.error("Robokassa payment processing error: #{e.message}")
      false
    end

    private

    def plan_price(plan)
      {
        'starter' => 590,
        'pro' => 1490,
        'business' => 2990
      }[plan] || 0
    end

    def generate_invoice_id
      Payment.maximum(:invoice_id).to_i + 1
    end

    def calculate_signature(*args)
      Digest::MD5.hexdigest(args.join(':'))
    end

    def activate_subscription(payment)
      subscription = @user.subscription || @user.build_subscription
      
      subscription.assign_attributes(
        plan: payment.description.split(' - ').last,
        status: :active,
        current_period_start: Time.current,
        current_period_end: 1.month.from_now
      )
      
      subscription.save!
    end
  end
end

# app/controllers/webhooks/robokassa_controller.rb
class Webhooks::RobokassaController < ApplicationController
  skip_before_action :verify_authenticity_token

  def result
    service = Payment::RobokassaService.new(nil, nil)
    
    if service.process_payment_result(params)
      render plain: "OK#{params[:InvId]}"
    else
      render plain: 'ERROR', status: :bad_request
    end
  end

  def success
    @payment = Payment.find_by(invoice_id: params[:InvId])
    
    if @payment&.completed?
      redirect_to dashboard_path, notice: 'Оплата прошла успешно!'
    else
      redirect_to billing_path, alert: 'Ошибка при обработке платежа'
    end
  end

  def fail
    redirect_to billing_path, alert: 'Оплата отменена'
  end
end
```

---

## 3. Технические требования

### 3.1 Технологический стек

#### 3.1.1 Backend

```ruby
# Gemfile
source 'https://rubygems.org'

ruby '3.3.0'

# Rails
gem 'rails', '~> 8.0'

# Database
gem 'pg', '~> 1.5'

# Redis
gem 'redis', '~> 5.0'

# Background Jobs (Rails 8 defaults)
gem 'solid_queue'
gem 'solid_cache'
gem 'solid_cable'

# Authentication
gem 'devise'
gem 'omniauth'
gem 'omniauth-telegram'

# Authorization
gem 'pundit'

# API
gem 'jbuilder'
gem 'rack-cors'

# Telegram
gem 'telegram-bot-ruby'

# HTTP Client
gem 'faraday'
gem 'faraday-retry'

# File uploads
gem 'aws-sdk-s3'
gem 'image_processing'

# Admin
gem 'administrate'

# Security
gem 'rack-attack'

# Monitoring
gem 'sentry-ruby'
gem 'sentry-rails'

# Performance
gem 'bullet', group: :development

# Testing
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry-rails'
  gem 'rubocop-rails-omakase', require: false
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webmock'
  gem 'vcr'
  gem 'simplecov', require: false
end
```

#### 3.1.2 Frontend

```javascript
// package.json
{
  "name": "contentforce",
  "private": true,
  "dependencies": {
    "@hotwired/stimulus": "^3.2.0",
    "@hotwired/turbo-rails": "^8.0.0",
    "esbuild": "^0.19.0",
    "alpinejs": "^3.13.0",
    "chart.js": "^4.4.0",
    "flatpickr": "^4.6.13",
    "markdown-it": "^14.0.0",
    "sortablejs": "^1.15.0"
  },
  "devDependencies": {
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.32",
    "tailwindcss": "^3.4.0"
  },
  "scripts": {
    "build": "esbuild app/javascript/*.* --bundle --sourcemap --outdir=app/assets/builds --public-path=/assets",
    "build:css": "tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/application.css"
  }
}
```

### 3.2 Архитектура базы данных

#### 3.2.1 Database Schema

```ruby
# db/schema.rb (основные таблицы)

create_table "users", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.string "email", null: false
  t.string "encrypted_password"
  t.bigint "telegram_id"
  t.string "telegram_username"
  t.string "first_name"
  t.string "last_name"
  t.string "avatar_url"
  t.datetime "confirmed_at"
  t.datetime "current_sign_in_at"
  t.integer "role", default: 0, null: false
  t.timestamps
  
  t.index ["email"], unique: true
  t.index ["telegram_id"], unique: true
  t.index ["role"]
end

create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "user_id", null: false
  t.string "name", null: false
  t.text "description"
  t.integer "category", default: 0
  t.integer "default_tone_of_voice", default: 0
  t.string "default_language", default: "ru"
  t.string "timezone", default: "UTC"
  t.string "ai_model"
  t.jsonb "settings", default: {}
  t.datetime "archived_at"
  t.timestamps
  
  t.index ["user_id"]
  t.index ["archived_at"]
end

create_table "telegram_bots", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "project_id", null: false
  t.string "bot_token", null: false
  t.string "bot_username"
  t.bigint "chat_id"
  t.string "chat_title"
  t.integer "chat_type", default: 0
  t.datetime "verified_at"
  t.datetime "last_sync_at"
  t.integer "status", default: 0
  t.text "error_message"
  t.timestamps
  
  t.index ["project_id"]
  t.index ["bot_username"], unique: true
end

create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "project_id", null: false
  t.uuid "telegram_bot_id"
  t.uuid "user_id", null: false
  t.string "title"
  t.text "content", null: false
  t.text "formatted_content"
  t.integer "post_type", default: 0
  t.integer "tone_of_voice"
  t.string "button_text"
  t.string "button_url"
  t.integer "status", default: 0
  t.datetime "scheduled_at"
  t.datetime "published_at"
  t.bigint "telegram_message_id"
  t.integer "views_count", default: 0
  t.jsonb "reactions", default: {}
  t.boolean "ai_generated", default: false
  t.text "ai_prompt"
  t.jsonb "metadata", default: {}
  t.timestamps
  
  t.index ["project_id"]
  t.index ["telegram_bot_id"]
  t.index ["user_id"]
  t.index ["status"]
  t.index ["scheduled_at"]
  t.index ["published_at"]
end

create_table "post_analytics", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "post_id", null: false
  t.date "date", null: false
  t.integer "views_count", default: 0
  t.integer "unique_views_count", default: 0
  t.integer "views_growth", default: 0
  t.timestamps
  
  t.index ["post_id", "date"], unique: true
end

create_table "button_click_events", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "post_id", null: false
  t.string "button_text"
  t.string "button_url"
  t.string "user_telegram_id"
  t.datetime "clicked_at"
  t.string "user_language"
  t.string "user_location"
  t.timestamps
  
  t.index ["post_id"]
  t.index ["clicked_at"]
end

create_table "channel_subscriber_metrics", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "telegram_bot_id", null: false
  t.date "date", null: false
  t.integer "total_subscribers", default: 0
  t.integer "new_subscribers", default: 0
  t.integer "unsubscribed", default: 0
  t.integer "net_growth", default: 0
  t.decimal "growth_rate", precision: 5, scale: 2, default: 0
  t.timestamps
  
  t.index ["telegram_bot_id", "date"], unique: true
end

create_table "subscriber_changes", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "telegram_bot_id", null: false
  t.uuid "post_id"
  t.integer "change_type", null: false
  t.string "user_telegram_id"
  t.datetime "occurred_at"
  t.integer "time_since_post"
  t.timestamps
  
  t.index ["telegram_bot_id"]
  t.index ["post_id"]
  t.index ["occurred_at"]
end

create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "user_id", null: false
  t.integer "plan", default: 0
  t.integer "status", default: 0
  t.datetime "current_period_start"
  t.datetime "current_period_end"
  t.boolean "cancel_at_period_end", default: false
  t.datetime "canceled_at"
  t.datetime "trial_ends_at"
  t.jsonb "limits", default: {}
  t.jsonb "usage", default: {}
  t.timestamps
  
  t.index ["user_id"], unique: true
  t.index ["status"]
  t.index ["current_period_end"]
end

create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "user_id", null: false
  t.uuid "subscription_id"
  t.decimal "amount", precision: 10, scale: 2, null: false
  t.string "currency", default: "RUB"
  t.integer "status", default: 0
  t.integer "provider", default: 0
  t.string "provider_payment_id"
  t.string "invoice_id"
  t.text "description"
  t.jsonb "metadata", default: {}
  t.datetime "paid_at"
  t.timestamps
  
  t.index ["user_id"]
  t.index ["subscription_id"]
  t.index ["invoice_id"], unique: true
  t.index ["status"]
end

create_table "ai_configurations", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.string "default_model", default: "claude-3-sonnet"
  t.jsonb "fallback_models", default: []
  t.decimal "temperature", precision: 3, scale: 2, default: 0.7
  t.integer "max_tokens", default: 2000
  t.text "custom_system_prompt"
  t.jsonb "enabled_features", default: {}
  t.timestamps
end

create_table "ai_usage_logs", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "user_id", null: false
  t.uuid "project_id"
  t.string "model_used"
  t.integer "tokens_used", default: 0
  t.decimal "cost", precision: 10, scale: 6, default: 0
  t.integer "purpose", default: 0
  t.timestamps
  
  t.index ["user_id"]
  t.index ["project_id"]
  t.index ["created_at"]
end

create_table "post_drafts", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "project_id", null: false
  t.uuid "user_id", null: false
  t.string "title"
  t.text "content"
  t.jsonb "settings", default: {}
  t.string "tags", array: true, default: []
  t.string "folder"
  t.jsonb "ai_conversation", default: []
  t.timestamps
  
  t.index ["project_id"]
  t.index ["user_id"]
end

create_table "templates", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "project_id"
  t.string "name", null: false
  t.text "description"
  t.text "content", null: false
  t.jsonb "variables", default: {}
  t.integer "category"
  t.integer "tone_of_voice"
  t.integer "usage_count", default: 0
  t.boolean "is_public", default: false
  t.timestamps
  
  t.index ["project_id"]
  t.index ["category"]
  t.index ["is_public"]
end

create_table "active_storage_blobs", id: :uuid do |t|
  t.string "key", null: false
  t.string "filename", null: false
  t.string "content_type"
  t.text "metadata"
  t.bigint "byte_size", null: false
  t.string "checksum"
  t.datetime "created_at", null: false
  
  t.index ["key"], unique: true
end

create_table "active_storage_attachments", id: :uuid do |t|
  t.string "name", null: false
  t.string "record_type", null: false
  t.uuid "record_id", null: false
  t.uuid "blob_id", null: false
  t.datetime "created_at", null: false
  
  t.index ["record_type", "record_id", "name", "blob_id"], 
          name: "index_active_storage_attachments_uniqueness", 
          unique: true
end
```

### 3.3 Безопасность

#### 3.3.1 Аутентификация и авторизация

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError
    end

    private

    attr_reader :user, :scope
  end
end

# app/policies/post_policy.rb
class PostPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.present? && (record.user == user || record.project.user == user)
  end

  def create?
    user.present? && can_create_post?
  end

  def update?
    user.present? && record.user == user
  end

  def destroy?
    user.present? && record.user == user
  end

  class Scope < Scope
    def resolve
      scope.joins(:project).where(projects: { user_id: user.id })
    end
  end

  private

  def can_create_post?
    return true unless user.subscription
    
    user.subscription.can_use?(:posts_per_month)
  end
end
```

#### 3.3.2 Rate Limiting

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle all requests by IP
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  # Throttle POST requests to /api/ by IP
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    if req.path.start_with?('/api') && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email
  throttle('logins/email', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.params['email'].to_s.downcase.gsub(/\s+/, '')
    end
  end

  # Throttle AI generation requests
  throttle('ai/generation', limit: 10, period: 1.minute) do |req|
    if req.path.start_with?('/api/v1/ai') && req.post?
      req.env['warden'].user&.id
    end
  end
end
```

#### 3.3.3 Encryption

```ruby
# config/initializers/encryption.rb
Rails.application.configure do
  # Encrypted credentials
  config.credentials.content_path = Rails.root.join("config/credentials/#{Rails.env}.yml.enc")
  
  # Active Record Encryption
  config.active_record.encryption.primary_key = ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY']
  config.active_record.encryption.deterministic_key = ENV['ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY']
  config.active_record.encryption.key_derivation_salt = ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT']
end
```

---

## 4. Дизайн и UX

### 4.1 Дизайн-система

#### 4.1.1 Tailwind Configuration

```javascript
// tailwind.config.js
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f5f7ff',
          100: '#ebefff',
          200: '#d6deff',
          300: '#b3c1ff',
          400: '#8c9eff',
          500: '#5b5fc7', // Main
          600: '#4a4da3',
          700: '#3a3d7f',
          800: '#2a2d5b',
          900: '#1a1d37',
        },
        // ... другие цвета
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
```

#### 4.1.2 Component Library

```erb
<!-- app/views/shared/_button.html.erb -->
<%
  variant = local_assigns.fetch(:variant, 'primary')
  size = local_assigns.fetch(:size, 'md')
  disabled = local_assigns.fetch(:disabled, false)
  loading = local_assigns.fetch(:loading, false)

  base_classes = "inline-flex items-center justify-center font-medium rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2"
  
  variant_classes = {
    'primary' => 'bg-primary-500 text-white hover:bg-primary-600 focus:ring-primary-500',
    'secondary' => 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus:ring-primary-500',
    'ghost' => 'text-gray-700 hover:bg-gray-100 focus:ring-primary-500',
    'danger' => 'bg-red-500 text-white hover:bg-red-600 focus:ring-red-500'
  }
  
  size_classes = {
    'sm' => 'px-3 py-1.5 text-sm',
    'md' => 'px-4 py-2 text-base',
    'lg' => 'px-6 py-3 text-lg'
  }
  
  classes = [
    base_classes,
    variant_classes[variant],
    size_classes[size],
    (disabled || loading) ? 'opacity-50 cursor-not-allowed' : ''
  ].join(' ')
%>

<button 
  type="<%= local_assigns.fetch(:type, 'button') %>"
  class="<%= classes %>"
  <%= 'disabled' if disabled || loading %>
  <%= local_assigns.fetch(:data, {}).map { |k, v| "data-#{k}=\"#{v}\"" }.join(' ').html_safe %>
>
  <% if loading %>
    <svg class="animate-spin -ml-1 mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    </svg>
  <% end %>
  <%= content %>
</button>
```

### 4.2 Responsive Design

```css
/* app/assets/stylesheets/application.tailwind.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer components {
  /* Post Editor Layout */
  .post-editor-grid {
    @apply grid gap-4;
    grid-template-columns: 1fr;
  }

  @screen md {
    .post-editor-grid {
      grid-template-columns: 1fr 2fr;
    }
  }

  @screen lg {
    .post-editor-grid {
      grid-template-columns: 3fr 2fr 5fr;
    }
  }

  /* Card styles */
  .card {
    @apply bg-white rounded-lg shadow-sm border border-gray-200 p-6;
  }

  .card-hover {
    @apply card transition-shadow hover:shadow-md;
  }

  /* Form styles */
  .form-group {
    @apply mb-4;
  }

  .form-label {
    @apply block text-sm font-medium text-gray-700 mb-1;
  }

  .form-input {
    @apply block w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500;
  }

  .form-error {
    @apply mt-1 text-sm text-red-600;
  }
}
```

---

## 5. Пользовательские сценарии (User Stories)

### 5.1 US-001: Регистрация через Telegram

```gherkin
Feature: Telegram Registration
  As a new user
  I want to register using my Telegram account
  So that I can quickly start using ContentForce

  Scenario: Successful Telegram registration
    Given I am on the homepage
    When I click "Войти через Telegram"
    And I authorize the application in Telegram
    Then I should be redirected to the onboarding flow
    And my account should be created with Telegram data

  Scenario: Existing Telegram user
    Given I already have an account linked to Telegram
    When I click "Войти через Telegram"
    And I authorize the application in Telegram
    Then I should be logged in
    And redirected to the dashboard
```

### 5.2 US-002: Создание поста с AI

```gherkin
Feature: AI Post Generation
  As a content creator
  I want to generate posts using AI
  So that I can save time on content creation

  Scenario: Generate post from prompt
    Given I am on the post creation page
    When I type "Напиши мотивационный пост про понедельник" in the AI chat
    And I click "Отправить"
    Then I should see the AI response in the preview within 5 seconds
    And the post should be formatted with proper markdown
    And I should be able to edit the generated text

  Scenario: Improve existing text
    Given I have a draft post with content
    When I click "Улучшить текст"
    Then the AI should suggest improvements
    And I can accept or reject the changes
```

### 5.3 US-003: Scheduled Publishing

```gherkin
Feature: Scheduled Publishing
  As a content manager
  I want to schedule posts for future publication
  So that I can plan content in advance

  Scenario: Schedule a post
    Given I have created a post
    When I select "Отложенная публикация"
    And I choose a date and time
    And I click "Запланировать"
    Then the post should appear in the calendar
    And it should be published automatically at the scheduled time

  Scenario: Reschedule a post
    Given I have a scheduled post
    When I drag it to a different date in the calendar
    Then the publication time should be updated
    And the background job should be rescheduled
```

### 5.4 US-004: View Analytics

```gherkin
Feature: Post Analytics
  As a channel owner with a paid plan
  I want to see detailed analytics for my posts
  So that I can understand what content performs best

  Scenario: View post performance
    Given I have published posts
    When I go to the analytics page
    Then I should see views, clicks, and subscriber changes
    And I should see a churn rate calculation
    And I should see which posts caused unsubscribes

  Scenario: Track button clicks
    Given I published a post with a button
    When users click the button
    Then I should see the click count increase
    And I should see click-through rate (CTR)
```

---

## 6. Аналитика и метрики

### 6.1 Product Metrics

```ruby
# app/services/metrics/dashboard_service.rb
module Metrics
  class DashboardService
    def product_health
      {
        users: user_metrics,
        revenue: revenue_metrics,
        engagement: engagement_metrics,
        technical: technical_metrics
      }
    end

    private

    def user_metrics
      {
        total_users: User.count,
        mau: User.where('current_sign_in_at > ?', 30.days.ago).count,
        dau: User.where('current_sign_in_at > ?', 1.day.ago).count,
        new_users_this_month: User.where('created_at > ?', 1.month.ago).count,
        paying_users: Subscription.active.where.not(plan: 'free').count,
        conversion_rate: calculate_conversion_rate
      }
    end

    def revenue_metrics
      {
        mrr: calculate_mrr,
        arr: calculate_mrr * 12,
        arpu: calculate_arpu,
        ltv: calculate_ltv,
        churn_rate: calculate_churn_rate
      }
    end

    def engagement_metrics
      {
        posts_per_user: Post.count.to_f / User.count,
        ai_generations_per_user: AiUsageLog.count.to_f / User.count,
        avg_session_duration: calculate_avg_session_duration,
        dau_mau_ratio: calculate_stickiness
      }
    end

    def technical_metrics
      {
        api_response_time_p95: calculate_p95_response_time,
        error_rate: calculate_error_rate,
        background_job_success_rate: calculate_job_success_rate,
        uptime: calculate_uptime
      }
    end

    # ... calculation methods
  end
end
```

### 6.2 Analytics Events Tracking

```javascript
// app/javascript/analytics/tracker.js
class AnalyticsTracker {
  constructor() {
    this.userId = document.querySelector('meta[name="user-id"]')?.content
  }

  track(eventName, properties = {}) {
    const event = {
      event: eventName,
      properties: {
        ...properties,
        timestamp: new Date().toISOString(),
        userId: this.userId,
        url: window.location.href,
        userAgent: navigator.userAgent
      }
    }

    // Send to backend
    fetch('/api/v1/analytics/events', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken()
      },
      body: JSON.stringify(event)
    })
  }

  // Convenience methods
  trackPostCreated(postId) {
    this.track('post_created', { postId })
  }

  trackAiGeneration(modelUsed, tokensUsed) {
    this.track('ai_generation', { modelUsed, tokensUsed })
  }

  trackPostPublished(postId, channel) {
    this.track('post_published', { postId, channel })
  }

  trackUpgrade(oldPlan, newPlan) {
    this.track('subscription_upgraded', { oldPlan, newPlan })
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}

// Initialize
window.analytics = new AnalyticsTracker()
```

---

## 7. Тестирование

### 7.1 RSpec Configuration

```ruby
# spec/rails_helper.rb
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'capybara/rspec'
require 'webmock/rspec'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Database Cleaner
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # Devise helpers
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller
end

# WebMock
WebMock.disable_net_connect!(allow_localhost: true)
```

### 7.2 Example Tests

```ruby
# spec/models/post_spec.rb
require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_most(4096) }
    
    context 'when post_type is image_button' do
      subject { build(:post, post_type: :image_button) }
      it { should validate_length_of(:button_text).is_at_most(64) }
    end
  end

  describe 'associations' do
    it { should belong_to(:project) }
    it { should belong_to(:user) }
    it { should belong_to(:telegram_bot).optional }
  end

  describe '#schedule_publication!' do
    let(:post) { create(:post, status: :scheduled, scheduled_at: 1.hour.from_now) }

    it 'enqueues a PublishPostJob' do
      expect {
        post.schedule_publication!
      }.to have_enqueued_job(PublishPostJob)
        .with(post.id)
        .at(post.scheduled_at)
    end
  end

  describe '#publish!' do
    let(:post) { create(:post, :with_telegram_bot) }
    let(:service) { instance_double(Telegram::PublishService) }

    before do
      allow(Telegram::PublishService).to receive(:new).and_return(service)
      allow(service).to receive(:publish!)
    end

    it 'calls Telegram::PublishService' do
      post.publish!
      expect(service).to have_received(:publish!)
    end
  end
end

# spec/services/ai/content_generator_spec.rb
require 'rails_helper'

RSpec.describe AI::ContentGenerator do
  let(:user) { create(:user, :with_pro_subscription) }
  let(:project) { create(:project, user: user) }
  let(:generator) { described_class.new(project: project, user: user) }

  describe '#generate' do
    let(:prompt) { 'Напиши пост про AI' }
    
    before do
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return(
          status: 200,
          body: {
            choices: [
              {
                message: { content: 'Generated content' }
              }
            ],
            model: 'claude-3-sonnet',
            usage: {
              prompt_tokens: 10,
              completion_tokens: 20,
              total_tokens: 30
            }
          }.to_json
        )
    end

    it 'generates content successfully' do
      result = generator.generate(prompt: prompt)
      expect(result).to eq('Generated content')
    end

    it 'tracks usage' do
      expect {
        generator.generate(prompt: prompt)
      }.to change(AiUsageLog, :count).by(1)
    end

    it 'increments subscription usage' do
      expect {
        generator.generate(prompt: prompt)
      }.to change { user.subscription.reload.usage_for(:ai_generations_per_month) }.by(1)
    end

    context 'when limit is exceeded' do
      before do
        user.subscription.update(
          usage: { ai_generations_per_month: 500 }
        )
      end

      it 'raises LimitExceededError' do
        expect {
          generator.generate(prompt: prompt)
        }.to raise_error(AI::LimitExceededError)
      end
    end
  end
end

# spec/requests/api/v1/posts_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::Posts', type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }

  before { sign_in user }

  describe 'GET /api/v1/projects/:project_id/posts' do
    it 'returns posts for the project' do
      posts = create_list(:post, 3, project: project, user: user)

      get "/api/v1/projects/#{project.id}/posts"

      expect(response).to have_http_status(:success)
      expect(json_response['posts'].size).to eq(3)
    end
  end

  describe 'POST /api/v1/projects/:project_id/posts' do
    let(:valid_attributes) do
      {
        post: {
          content: 'Test post content',
          post_type: 'text',
          status: 'draft'
        }
      }
    end

    it 'creates a new post' do
      expect {
        post "/api/v1/projects/#{project.id}/posts", params: valid_attributes
      }.to change(Post, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end
end

# spec/system/post_creation_spec.rb
require 'rails_helper'

RSpec.describe 'Post Creation', type: :system, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:telegram_bot) { create(:telegram_bot, project: project) }

  before do
    sign_in user
    visit new_project_post_path(project)
  end

  it 'allows creating a post with AI' do
    # Type in AI chat
    fill_in 'ai-chat-input', with: 'Напиши пост про AI'
    click_button 'Отправить'

    # Wait for AI response
    expect(page).to have_content('Generated content', wait: 10)

    # Preview should update
    within '.post-preview' do
      expect(page).to have_content('Generated content')
    end

    # Publish
    click_button 'Опубликовать'

    expect(page).to have_content('Пост успешно опубликован')
  end

  it 'allows scheduling a post' do
    fill_in 'post_content', with: 'Scheduled post'
    
    select 'Отложенная публикация', from: 'publication_type'
    fill_in 'scheduled_at', with: 1.hour.from_now

    click_button 'Запланировать'

    expect(page).to have_content('Пост запланирован')
    
    # Should appear in calendar
    visit calendar_path
    expect(page).to have_content('Scheduled post')
  end
end
```

### 7.3 Test Factories

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password123' }
    confirmed_at { Time.current }

    trait :with_telegram do
      telegram_id { Faker::Number.unique.number(digits: 10) }
      telegram_username { Faker::Internet.username }
    end

    trait :with_free_subscription do
      after(:create) do |user|
        create(:subscription, :free, user: user)
      end
    end

    trait :with_pro_subscription do
      after(:create) do |user|
        create(:subscription, :pro, user: user)
      end
    end

    trait :admin do
      role { :admin }
    end
  end
end

# spec/factories/projects.rb
FactoryBot.define do
  factory :project do
    association :user
    name { Faker::Company.name }
    description { Faker::Lorem.paragraph }
    category { :business }
    default_tone_of_voice { :professional }
  end
end

# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    association :project
    association :user
    content { Faker::Lorem.paragraph(sentence_count: 5) }
    post_type { :text }
    status { :draft }

    trait :scheduled do
      status { :scheduled }
      scheduled_at { 1.hour.from_now }
    end

    trait :published do
      status { :published }
      published_at { 1.hour.ago }
      telegram_message_id { Faker::Number.number(digits: 10) }
    end

    trait :with_telegram_bot do
      association :telegram_bot
    end

    trait :with_button do
      post_type { :image_button }
      button_text { 'Click me' }
      button_url { 'https://example.com' }
    end
  end
end

# spec/factories/subscriptions.rb
FactoryBot.define do
  factory :subscription do
    association :user
    plan { :free }
    status { :active }
    current_period_start { Time.current }
    current_period_end { 1.month.from_now }

    trait :free do
      plan { :free }
    end

    trait :starter do
      plan { :starter }
    end

    trait :pro do
      plan { :pro }
    end

    trait :business do
      plan { :business }
    end

    trait :canceled do
      status { :canceled }
      canceled_at { Time.current }
      cancel_at_period_end { true }
    end
  end
end
```

---

## 8. Развертывание и инфраструктура

### 8.1 Docker Configuration

```dockerfile
# Dockerfile
FROM ruby:3.3.0-alpine AS base

# Install dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    nodejs \
    npm \
    git \
    tzdata \
    imagemagick \
    vips \
    vips-dev

WORKDIR /app

# Install gems
FROM base AS dependencies

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install -j4

# Install Node packages
COPY package.json package-lock.json ./
RUN npm ci --production

# Build stage
FROM dependencies AS build

COPY . .

# Precompile assets
RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# Production stage
FROM base AS production

COPY --from=dependencies /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

# Create non-root user
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

USER appuser

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

### 8.2 Docker Compose

```yaml
# docker-compose.yml
version: '3.9'

services:
  db:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: contentforce
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: contentforce_production
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U contentforce"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  web:
    build:
      context: .
      target: production
    command: bundle exec rails server -b 0.0.0.0
    volumes:
      - storage_data:/app/storage
    ports:
      - "3000:3000"
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://contentforce:${DB_PASSWORD}@db:5432/contentforce_production
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: production
      RAILS_SERVE_STATIC_FILES: 'true'
      RAILS_LOG_TO_STDOUT: 'true'
    env_file:
      - .env

  worker:
    build:
      context: .
      target: production
    command: bundle exec rails solid_queue:start
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://contentforce:${DB_PASSWORD}@db:5432/contentforce_production
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: production
    env_file:
      - .env

volumes:
  postgres_data:
  redis_data:
  storage_data:
```

### 8.3 Coolify Deployment

#### 8.3.1 Coolify Configuration

**Project Settings в Coolify:**
```yaml
Name: ContentForce
Type: Application
Source: GitHub
Repository: your-username/contentForceTG
Branch: main
Build Pack: Dockerfile
Port: 3000
```

**Environment Variables:**
```bash
# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=<your_master_key>
SECRET_KEY_BASE=<generate_with_rails_secret>
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true

# Database
DATABASE_URL=postgresql://user:password@postgres:5432/contentforce_production

# Redis
REDIS_URL=redis://redis:6379/0

# OpenRouter
OPENROUTER_API_KEY=<your_api_key>
OPENROUTER_SITE_URL=https://contentforce.io
OPENROUTER_SITE_NAME=ContentForce

# Robokassa
ROBOKASSA_LOGIN=<your_login>
ROBOKASSA_PASSWORD_1=<password_1>
ROBOKASSA_PASSWORD_2=<password_2>
ROBOKASSA_TEST_MODE=false

# AWS S3
AWS_ACCESS_KEY_ID=<your_key>
AWS_SECRET_ACCESS_KEY=<your_secret>
AWS_REGION=eu-central-1
AWS_BUCKET=contentforce-production

# Sentry
SENTRY_DSN=<your_dsn>
```

#### 8.3.2 Deploy Script

```bash
#!/bin/bash
# .coolify/deploy.sh

set -e

echo "🚀 Starting deployment..."

# Wait for database
echo "⏳ Waiting for database..."
until pg_isready -h db -U contentforce; do
  sleep 1
done

# Run migrations
echo "📝 Running database migrations..."
bundle exec rails db:migrate

# Clear cache
echo "🗑️  Clearing cache..."
bundle exec rails cache:clear

# Precompile assets (if not done in Dockerfile)
if [ ! -d "public/assets" ]; then
  echo "🎨 Precompiling assets..."
  bundle exec rails assets:precompile
fi

# Restart workers
echo "👷 Restarting background workers..."
pkill -f solid_queue || true

echo "✅ Deployment completed successfully!"
```

#### 8.3.3 Health Check

```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  skip_before_action :authenticate_user!
  
  def check
    checks = {
      database: check_database,
      redis: check_redis,
      workers: check_workers,
      storage: check_storage
    }
    
    all_healthy = checks.values.all? { |v| v[:status] == 'ok' }
    status = all_healthy ? :ok : :service_unavailable
    
    render json: {
      status: all_healthy ? 'healthy' : 'unhealthy',
      timestamp: Time.current.iso8601,
      version: Rails.application.config.version,
      checks: checks
    }, status: status
  end
  
  private
  
  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    { status: 'ok', message: 'Database connected' }
  rescue => e
    { status: 'error', message: e.message }
  end
  
  def check_redis
    Redis.new(url: ENV['REDIS_URL']).ping
    { status: 'ok', message: 'Redis connected' }
  rescue => e
    { status: 'error', message: e.message }
  end
  
  def check_workers
    active_workers = SolidQueue::Worker.active.count
    if active_workers > 0
      { status: 'ok', message: "#{active_workers} workers active" }
    else
      { status: 'warning', message: 'No active workers' }
    end
  rescue => e
    { status: 'error', message: e.message }
  end

  def check_storage
    ActiveStorage::Blob.first
    { status: 'ok', message: 'Storage accessible' }
  rescue => e
    { status: 'error', message: e.message }
  end
end
```

### 8.4 CI/CD with GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: contentforce
          POSTGRES_PASSWORD: password
          POSTGRES_DB: contentforce_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.3.0
        bundler-cache: true
    
    - name: Set up Node
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'
    
    - name: Install dependencies
      run: |
        bundle install
        npm ci
    
    - name: Setup test database
      env:
        DATABASE_URL: postgresql://contentforce:password@localhost:5432/contentforce_test
        REDIS_URL: redis://localhost:6379/0
        RAILS_ENV: test
      run: |
        bundle exec rails db:create
        bundle exec rails db:schema:load
    
    - name: Run RuboCop
      run: bundle exec rubocop
    
    - name: Run Brakeman
      run: bundle exec brakeman --no-pager
    
    - name: Run RSpec
      env:
        DATABASE_URL: postgresql://contentforce:password@localhost:5432/contentforce_test
        REDIS_URL: redis://localhost:6379/0
        RAILS_ENV: test
      run: |
        bundle exec rspec
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage/coverage.json

# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Trigger Coolify Deployment
      run: |
        curl -X POST "${{ secrets.COOLIFY_WEBHOOK_URL }}" \
          -H "Authorization: Bearer ${{ secrets.COOLIFY_TOKEN }}"
    
    - name: Wait for deployment
      run: sleep 60
    
    - name: Health check
      run: |
        for i in {1..10}; do
          if curl -f https://contentforce.io/health; then
            echo "✅ Deployment successful!"
            exit 0
          fi
          echo "⏳ Waiting for service... ($i/10)"
          sleep 10
        done
        echo "❌ Deployment failed!"
        exit 1
    
    - name: Notify on failure
      if: failure()
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        text: 'Deployment failed!'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 8.5 Backup Strategy

```bash
#!/bin/bash
# scripts/backup.sh

set -e

BACKUP_DIR="/backups/contentforce"
DATE=$(date +%Y%m%d_%H%M%S)
S3_BUCKET="contentforce-backups"

echo "📦 Starting backup at $DATE"

# Database backup
echo "💾 Backing up database..."
PGPASSWORD=$DB_PASSWORD pg_dump \
  -h localhost \
  -U contentforce \
  -d contentforce_production \
  | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# Files backup (if using local storage)
if [ -d "/app/storage" ]; then
  echo "📁 Backing up storage files..."
  tar -czf "$BACKUP_DIR/storage_$DATE.tar.gz" /app/storage
fi

# Upload to S3
echo "☁️  Uploading to S3..."
aws s3 cp "$BACKUP_DIR/db_$DATE.sql.gz" "s3://$S3_BUCKET/databases/"

if [ -f "$BACKUP_DIR/storage_$DATE.tar.gz" ]; then
  aws s3 cp "$BACKUP_DIR/storage_$DATE.tar.gz" "s3://$S3_BUCKET/storage/"
fi

# Cleanup old local backups (keep last 7 days)
echo "🗑️  Cleaning up old backups..."
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +7 -delete
find $BACKUP_DIR -name "storage_*.tar.gz" -mtime +7 -delete

# Cleanup old S3 backups (keep last 30 days)
aws s3 ls "s3://$S3_BUCKET/databases/" | \
  awk '{print $4}' | \
  head -n -30 | \
  xargs -I {} aws s3 rm "s3://$S3_BUCKET/databases/{}"

echo "✅ Backup completed: db_$DATE.sql.gz"
```

**Cron job (добавить в Coolify или сервер):**
```cron
# Daily backup at 3 AM
0 3 * * * /app/scripts/backup.sh >> /var/log/backup.log 2>&1
```

---

## 9. Roadmap и приоритеты

### 9.1 MVP (2-3 месяца)

**Must-have функции:**
- ✅ Регистрация (Telegram + Email)
- ✅ Создание проектов
- ✅ Подключение Telegram-ботов
- ✅ Создание постов (текст, изображение, изображение+кнопка)
- ✅ AI-генерация контента через OpenRouter
- ✅ Публикация в Telegram
- ✅ Отложенная публикация
- ✅ Календарь публикаций
- ✅ Черновики
- ✅ Базовая аналитика (просмотры)
- ✅ Тарифы и оплата (Robokassa)
- ✅ Админ-панель (Administrate)

### 9.2 Post-MVP - Фаза 1 (1-2 месяца)

**Высокий приоритет:**
- 🔄 Расширенная аналитика (клики, подписчики, churn rate)
- 🔄 Отслеживание кликов по кнопкам
- 🔄 Шаблоны постов
- 🔄 AI-генерация изображений (DALL-E)
- 🔄 Библиотека медиа
- 🔄 Поиск по постам
- 🔄 Темная тема
- 🔄 PWA (мобильная версия)

### 9.3 Фаза 2 (2-3 месяца)

**Средний приоритет:**
- 📋 Подключение VK
- 📋 Подключение Instagram (через Facebook API)
- 📋 Командная работа (роли и права)
- 📋 API для интеграций
- 📋 Webhooks для событий
- 📋 Массовая публикация
- 📋 Конструктор постов (drag & drop)
- 📋 A/B тестирование постов

### 9.4 Будущие фичи (Backlog)

**Низкий приоритет:**
- 📝 Мультиязычность интерфейса
- 📝 AI-инсайты и рекомендации
- 📝 Интеграция с CRM
- 📝 Чат-боты для взаимодействия с аудиторией
- 📝 Видеопосты
- 📝 Stories для Instagram
- 📝 Автоматическая модерация комментариев
- 📝 Белый лейбл для агентств
- 📝 Marketplace шаблонов

---

## 10. Риски и митигация

### 10.1 Технические риски

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| Telegram API ограничения | Высокая | Высокое | Rate limiting, очереди, retry механизм |
| AI API costs | Средняя | Высокое | Лимиты по тарифам, кэширование, оптимизация промптов |
| Scalability проблемы | Средняя | Высокое | Horizontal scaling, load testing, database partitioning |
| Security vulnerabilities | Средняя | Критическое | Regular audits, dependency updates, penetration testing |

### 10.2 Бизнес риски

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| Низкая конверсия Free → Paid | Средняя | Критическое | Onboarding optimization, email campaigns, in-app prompts |
| Высокий churn rate | Средняя | Высокое | Customer success, feature updates, feedback collection |
| Конкуренция | Высокая | Среднее | Unique features, fast iterations, strong branding |
| Market size | Низкая | Среднее | Market research, pivot readiness |

### 10.3 Legal риски

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| Нарушение ToS Telegram | Низкая | Критическое | Strict ToS compliance, anti-spam measures, legal review |
| GDPR/Персональные данные | Средняя | Высокое | Privacy policy, consent management, data deletion |
| Налоговое законодательство | Средняя | Среднее | Proper business registration, accounting, legal consultation |

---

## 11. Метрики успеха

### 11.1 Launch метрики (первые 3 месяца)

- **Пользователи:**
  - 1,000+ регистраций
  - 200+ активных пользователей (публикуют ≥1 раз в неделю)
  - 50+ платящих пользователей
  
- **Engagement:**
  - 10,000+ публикаций
  - 50,000+ AI-генераций
  - DAU/MAU ratio > 0.2
  
- **Revenue:**
  - 30,000₽+ MRR
  - Conversion rate Free→Paid > 5%
  
- **Quality:**
  - NPS > 5
  - Uptime > 99%
  - Support response time < 24h

### 11.2 Год 1 метрики

- **Пользователи:**
  - 10,000+ регистраций
  - 2,000+ MAU
  - 500+ платящих пользователей
  
- **Revenue:**
  - 300,000₽+ MRR (3.6M ARR)
  - LTV/CAC > 3
  - Churn rate < 5%
  
- **Product:**
  - 100,000+ публикаций
  - 1,000,000+ AI-генераций
  - 20+ NPS

### 11.3 Success критерии для MVP

✅ Onboarding completion rate > 80%  
✅ Time to first publish < 10 минут  
✅ AI generation success rate > 95%  
✅ Publication success rate > 99%  
✅ Uptime > 99%  
✅ User satisfaction > 4.0/5.0  
✅ Payment success rate > 95%

---

## 12. Поддержка и документация

### 12.1 Пользовательская документация

**Обязательные материалы:**
- Getting Started Guide
- Как создать Telegram-бота (step-by-step с скриншотами)
- Как использовать AI для создания контента
- Как планировать публикации
- Расшифровка аналитики
- FAQ
- Видео-туториалы (YouTube)

**Платформа:**
- Help Center (встроенный в приложение)
- docs.contentforce.io
- Intercom или Crisp для live chat

### 12.2 Техническая документация

**Для разработчиков (API):**
- API Documentation (Swagger/OpenAPI)
- Authentication Guide
- Webhooks Guide
- Rate Limits
- Code Examples
- SDKs (будущее)

### 12.3 Customer Support

**Каналы:**
- Email: support@contentforce.io
- Telegram: @contentforce_support
- In-app chat (для платных тарифов)
- Knowledge base

**SLA по тарифам:**
- Free: Best effort, email only
- Starter: 24 часа, email
- Pro: 12 часов, email + chat
- Business: 4 часа, priority, персональный менеджер

---

## 13. Compliance и Legal

### 13.1 Необходимые документы

- ✅ Политика конфиденциальности (Privacy Policy)
- ✅ Пользовательское соглашение (Terms of Service)
- ✅ Политика возврата средств (Refund Policy)
- ✅ Политика использования cookies
- ✅ Договор оферты для юрлиц

### 13.2 Требования законодательства РФ

- Регистрация ИП/ООО
- Договор с Robokassa
- Фискализация (54-ФЗ) - онлайн-касса
- Обработка персональных данных (152-ФЗ)
- Уведомление Роскомнадзора об обработке ПД

### 13.3 Intellectual Property

- Регистрация товарного знака "ContentForce"
- Copyright на контент и код
- Лицензии на используемые библиотеки (MIT, Apache 2.0)

---

## 14. Приложения

### 14.1 Environment Variables

```bash
# .env.example

# Application
APP_URL=https://contentforce.io
RAILS_ENV=production
RAILS_MASTER_KEY=
SECRET_KEY_BASE=
DEFAULT_FROM_EMAIL=noreply@contentforce.io

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/contentforce_production

# Redis
REDIS_URL=redis://localhost:6379/0

# Telegram
TELEGRAM_BOT_TOKEN=

# OpenRouter AI
OPENROUTER_API_KEY=
OPENROUTER_SITE_URL=https://contentforce.io
OPENROUTER_SITE_NAME=ContentForce

# Robokassa
ROBOKASSA_LOGIN=
ROBOKASSA_PASSWORD_1=
ROBOKASSA_PASSWORD_2=
ROBOKASSA_TEST_MODE=false

# AWS S3
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=eu-central-1
AWS_BUCKET=contentforce-production

# Active Record Encryption
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=

# Sentry
SENTRY_DSN=

# SMTP
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=
SMTP_DOMAIN=contentforce.io
```

### 14.2 Git Repository Structure

```
contentForceTG/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── deploy.yml
├── app/
│   ├── assets/
│   ├── channels/
│   ├── controllers/
│   │   ├── admin/
│   │   ├── api/
│   │   │   └── v1/
│   │   └── webhooks/
│   ├── dashboards/
│   ├── helpers/
│   ├── javascript/
│   │   ├── controllers/
│   │   └── channels/
│   ├── jobs/
│   │   └── analytics/
│   ├── mailers/
│   ├── models/
│   ├── policies/
│   ├── services/
│   │   ├── ai/
│   │   ├── payment/
│   │   └── telegram/
│   └── views/
├── config/
│   ├── credentials/
│   ├── environments/
│   ├── initializers/
│   ├── locales/
│   ├── application.rb
│   ├── database.yml
│   ├── routes.rb
│   └── storage.yml
├── db/
│   ├── migrate/
│   ├── schema.rb
│   └── seeds.rb
├── lib/
│   └── openrouter/
│       └── client.rb
├── public/
├── spec/
│   ├── factories/
│   ├── models/
│   ├── requests/
│   ├── services/
│   ├── support/
│   ├── system/
│   ├── rails_helper.rb
│   └── spec_helper.rb
├── scripts/
│   ├── backup.sh
│   └── deploy.sh
├── .coolify/
│   └── deploy.sh
├── .dockerignore
├── .env.example
├── .gitignore
├── .rubocop.yml
├── Dockerfile
├── docker-compose.yml
├── Gemfile
├── Gemfile.lock
├── package.json
├── package-lock.json
├── Procfile
├── README.md
└── tailwind.config.js
```

### 14.3 Команды для разработки

```bash
# Setup
bundle install
npm install
rails db:create db:migrate db:seed

# Development
bin/dev  # Starts Rails server, CSS watcher, JS builder

# Testing
rspec                          # Run all tests
rspec spec/models              # Run model tests
rspec spec/requests            # Run request tests
rspec spec/system              # Run system tests

# Code Quality
rubocop                        # Lint Ruby code
rubocop -a                     # Auto-fix issues
bundle exec brakeman           # Security scan

# Database
rails db:migrate               # Run migrations
rails db:rollback              # Rollback last migration
rails db:reset                 # Reset database

# Console
rails console                  # Open Rails console
rails dbconsole               # Open database console

# Deployment
docker-compose up              # Start all services
docker-compose down            # Stop all services
```

### 14.4 Бюджет разработки MVP

| Категория | Стоимость | Период |
|-----------|-----------|--------|
| **Разработка** | | |
| Backend developer | 450,000₽ | 3 месяца |
| Frontend developer | 300,000₽ | 2 месяца |
| UI/UX Designer | 100,000₽ | 1 месяц |
| **Инфраструктура (год)** | | |
| Hosting (Hetzner) | 60,000₽ | 12 месяцев |
| S3 Storage | 12,000₽ | 12 месяцев |
| Domain + SSL | 3,000₽ | 12 месяцев |
| AI API (OpenRouter) | 120,000₽ | 12 месяцев |
| Monitoring (Sentry) | 24,000₽ | 12 месяцев |
| **Сервисы (год)** | | |
| Email (SendGrid) | 12,000₽ | 12 месяцев |
| Analytics | 24,000₽ | 12 месяцев |
| **Юридические** | | |
| Регистрация ИП/ООО | 15,000₽ | Один раз |
| Договоры и документы | 30,000₽ | Один раз |
| **Маркетинг (первый год)** | | |
| Landing page | 50,000₽ | Один раз |
| Контент-маркетинг | 120,000₽ | 12 месяцев |
| Реклама | 300,000₽ | 12 месяцев |
| **ИТОГО MVP** | **~1,620,000₽** | |

---

## Контакты и Next Steps

### Команда проекта
- **Product Owner:** [Имя]
- **Tech Lead:** [Имя]
- **Backend Developer:** [Имя]
- **Frontend Developer:** [Имя]
- **Designer:** [Имя]

### Контакты
- **Website:** https://contentforce.io
- **Email:** hello@contentforce.io
- **Telegram:** @contentforce
- **GitHub:** github.com/your-username/contentForceTG

### Next Steps

1. **Week 1-2:** 
   - Настройка инфраструктуры
   - Базовая структура Rails приложения
   - Настройка CI/CD

2. **Week 3-4:**
   - Аутентификация и регистрация
   - Модели данных
   - Админ-панель

3. **Week 5-8:**
   - Интеграция Telegram Bot API
   - AI интеграция через OpenRouter
   - Интерфейс создания постов

4. **Week 9-10:**
   - Календарь и планирование
   - Аналитика
   - Robokassa интеграция

5. **Week 11-12:**
   - Тестирование
   - Bug fixes
   - Deployment на Coolify
   - Beta launch

---

**Версия документа:** 1.1  
**Последнее обновление:** 10 января 2026  
**Статус:** ✅ Ready for Development  
**Repository:** contentForceTG

---

*Этот PRD является живым документом и будет обновляться по мере развития продукта и получения обратной связи.*
