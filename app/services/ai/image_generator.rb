# frozen_string_literal: true

module Ai
  # Сервис генерации изображений с помощью AI
  # Поддерживает модели: Gemini Flash Image, Flux 1.1 Pro
  class ImageGenerator
    # Доступные модели для генерации изображений
    # Актуальные ID: curl https://openrouter.ai/api/v1/models | jq '.data[] | select(.id | contains("image"))'
    AVAILABLE_MODELS = {
      "google/gemini-2.5-flash-image" => {
        name: "Gemini Flash Image",
        description: "Быстрая генерация, хорошее качество",
        cost_per_image: 0.04
      },
      "google/gemini-3-pro-image-preview" => {
        name: "Gemini 3 Pro Image",
        description: "Высокое качество, продвинутая модель",
        cost_per_image: 0.06
      }
    }.freeze

    # Модель по умолчанию
    DEFAULT_MODEL = "google/gemini-2.5-flash-image"

    # Доступные соотношения сторон
    ASPECT_RATIOS = {
      "1:1" => "Квадрат",
      "16:9" => "Широкое",
      "9:16" => "Вертикальное",
      "4:3" => "Стандартное",
      "3:4" => "Портрет"
    }.freeze

    def initialize(project: nil, user: nil)
      @project = project
      @user = user
      @config = AiConfiguration.current
      @client = Openrouter::Client.new
    end

    # Генерация изображения по текстовому промпту
    # @param prompt [String] описание желаемого изображения
    # @param aspect_ratio [String] соотношение сторон (1:1, 16:9, 9:16)
    # @param model [String] модель для генерации (опционально)
    # @return [Hash] результат с image_data, content_type или ошибкой
    def generate(prompt:, aspect_ratio: "1:1", model: nil)
      model ||= DEFAULT_MODEL

      # Проверяем, что модель поддерживается
      unless AVAILABLE_MODELS.key?(model)
        return {
          success: false,
          error: "Модель #{model} не поддерживается для генерации изображений"
        }
      end

      # Проверка лимитов тарифа
      unless can_generate?
        return {
          success: false,
          error: "Превышен лимит AI генераций для вашего тарифа"
        }
      end

      Rails.logger.info "=== AI Image Generation ==="
      Rails.logger.info "Model: #{model}"
      Rails.logger.info "Aspect Ratio: #{aspect_ratio}"
      Rails.logger.info "Prompt: #{prompt[0..100]}..."

      # Улучшаем промпт для лучших результатов
      enhanced_prompt = enhance_prompt(prompt, aspect_ratio)

      # Вызов OpenRouter API
      response = @client.generate_image(
        model: model,
        prompt: enhanced_prompt,
        aspect_ratio: aspect_ratio
      )

      # Трекинг использования
      track_usage(response, model)

      Rails.logger.info "Image generation successful!"

      {
        success: true,
        image_data: response[:image_data],
        content_type: response[:content_type],
        model_used: response[:model] || model
      }
    rescue Openrouter::ConfigurationError => e
      Rails.logger.error "OpenRouter configuration error: #{e.message}"
      {
        success: false,
        error: "OpenRouter API ключ не настроен. Обратитесь к администратору."
      }
    rescue Openrouter::APIError => e
      Rails.logger.error "OpenRouter API error: #{e.message}"
      {
        success: false,
        error: "Ошибка API: #{e.message}"
      }
    rescue StandardError => e
      Rails.logger.error "Image Generation error: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      {
        success: false,
        error: "Произошла ошибка: #{e.message}"
      }
    end

    # Возвращает список доступных моделей для UI
    def self.available_models
      AVAILABLE_MODELS.map do |id, info|
        {
          id: id,
          name: info[:name],
          description: info[:description]
        }
      end
    end

    # Возвращает список доступных соотношений сторон для UI
    def self.aspect_ratios
      ASPECT_RATIOS.map { |value, label| { value: value, label: label } }
    end

    private

    # Улучшение промпта для лучших результатов генерации
    def enhance_prompt(prompt, aspect_ratio)
      # Базовые улучшения для качества изображения
      enhancements = [
        prompt,
        "high quality",
        "detailed",
        "professional"
      ]

      # Добавляем контекст проекта если есть
      if @project&.name.present?
        enhancements << "for #{@project.name} brand"
      end

      enhancements.join(", ")
    end

    # Отслеживание использования AI для биллинга и аналитики
    def track_usage(response, model)
      return unless @user

      usage = response[:usage] || {}
      model_info = AVAILABLE_MODELS[model] || {}
      cost = model_info[:cost_per_image] || 0.04

      AiUsageLog.create!(
        user: @user,
        project: @project,
        model_used: model,
        tokens_used: usage[:total_tokens] || 0,
        input_tokens: usage[:prompt_tokens] || 0,
        output_tokens: usage[:completion_tokens] || 0,
        input_cost: 0,
        output_cost: cost,
        cost: cost,
        purpose: :image_generation
      )

      # Списываем квоту
      @user.subscription&.increment_usage!(:ai_generations_per_month)
    end

    # Проверка возможности генерации (лимиты тарифа)
    def can_generate?
      return true unless @user&.subscription

      @user.subscription.can_use?(:ai_generations_per_month)
    end
  end
end
