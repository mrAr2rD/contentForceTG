# frozen_string_literal: true

module Ai
  class ContentGenerator
    def initialize(project: nil, user: nil)
      @project = project
      @user = user
      @config = AiConfiguration.current
      @client = Openrouter::Client.new
    end

    def generate(prompt:, context: {})
      # Получаем модель из настроек проекта или глобальных настроек
      model = context[:model] || @project&.ai_model || @config.default_model

      # Проверка лимитов тарифа (только для платных моделей)
      unless AiConfiguration.free_model?(model) || can_generate?
        return {
          content: nil,
          error: 'Превышен лимит AI генераций для вашего тарифа',
          success: false
        }
      end

      # Получаем температуру из настроек проекта или глобальных
      temperature = @project&.ai_temperature || @config.temperature

      Rails.logger.info "=== AI Content Generation ==="
      Rails.logger.info "Model: #{model}"
      Rails.logger.info "Temperature: #{temperature}"
      Rails.logger.info "Prompt length: #{prompt.length}"

      # Строим системный промпт с контекстом проекта
      system_prompt = build_system_prompt(context)

      # Вызов OpenRouter API
      response = call_openrouter(
        model: model,
        system: system_prompt,
        user_message: prompt,
        temperature: temperature,
        max_tokens: @config.max_tokens
      )

      # Трекинг использования
      track_usage(response)

      Rails.logger.info "Generation successful! Tokens: #{response[:usage][:total_tokens]}"

      {
        content: response[:content],
        model_used: response[:model],
        tokens_used: response[:usage][:total_tokens],
        success: true
      }
    rescue Openrouter::ConfigurationError => e
      Rails.logger.error "OpenRouter configuration error: #{e.message}"
      {
        content: nil,
        error: 'OpenRouter API ключ не настроен. Обратитесь к администратору.',
        success: false
      }
    rescue Openrouter::APIError => e
      Rails.logger.error "OpenRouter API error: #{e.message}"
      {
        content: nil,
        error: "Ошибка API: #{e.message}",
        success: false
      }
    rescue StandardError => e
      Rails.logger.error "AI Generation error: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      {
        content: nil,
        error: "Произошла ошибка: #{e.message}",
        success: false
      }
    end

    def improve(content:, instruction:)
      prompt = <<~PROMPT
        Улучши следующий текст поста для Telegram согласно инструкции.
        
        Текст:
        #{content}
        
        Инструкция: #{instruction}
        
        Верни только улучшенный текст без пояснений.
      PROMPT

      generate(prompt: prompt)
    end

    def generate_hashtags(content:, count: 5)
      prompt = <<~PROMPT
        Сгенерируй #{count} релевантных хештегов для следующего поста. 
        Верни только хештеги через пробел.
        
        Пост:
        #{content}
      PROMPT

      result = generate(prompt: prompt)

      if result[:success]
        hashtags = result[:content].to_s.scan(/#\w+/)
        result[:hashtags] = hashtags
      end

      result
    end

    private

    def call_openrouter(model:, system:, user_message:, temperature:, max_tokens:)
      response = @client.chat(
        model: model,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user_message }
        ],
        temperature: temperature.to_f,  # Ensure temperature is a Float
        max_tokens: max_tokens.to_i,    # Ensure max_tokens is an Integer
        transforms: ['middle-out'],
        route: 'fallback'
      )

      response
    end

    def build_system_prompt(context)
      # Используем системный промпт из проекта, если есть
      base_prompt = if @project&.system_prompt.present?
                      @project.system_prompt
                    else
                      @config.custom_system_prompt || default_system_prompt
                    end

      if @project
        base_prompt += "\n\nПроект: #{@project.name}"

        # Добавляем стиль написания из настроек проекта
        if @project.writing_style.present?
          base_prompt += "\nСтиль написания: #{@project.writing_style}"
        end

        base_prompt += "\nОписание: #{@project.description}" if @project.description.present?
      end

      if context[:previous_posts]
        base_prompt += "\n\nПримеры предыдущих постов:\n"
        context[:previous_posts].each do |post|
          base_prompt += "- #{post.content[0..200]}\n"
        end
      end

      if context[:tone_of_voice]
        base_prompt += "\n\nДополнительные указания по тону: #{context[:tone_of_voice]}"
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
        rescue StandardError => e
          next
        end
      end

      raise GenerationError, 'All AI models failed. Please try again later.'
    end

    def track_usage(response)
      return unless @user

      usage = response[:usage]
      cost_data = calculate_cost(response)

      AiUsageLog.create!(
        user: @user,
        project: @project,
        model_used: response[:model],
        tokens_used: usage[:total_tokens],
        input_tokens: usage[:prompt_tokens] || 0,
        output_tokens: usage[:completion_tokens] || 0,
        input_cost: cost_data[:input_cost],
        output_cost: cost_data[:output_cost],
        cost: cost_data[:total_cost],
        purpose: :content_generation
      )

      # Не списываем квоту для бесплатных моделей
      return if AiModel.free_model?(response[:model])

      if @user.subscription
        @user.subscription.increment_usage!(:ai_generations_per_month)
      end
    end

    def can_generate?
      return true unless @user&.subscription

      @user.subscription.can_use?(:ai_generations_per_month)
    end

    def calculate_cost(response)
      usage = response[:usage]
      return { input_cost: 0, output_cost: 0, total_cost: 0 } unless usage

      input_tokens = usage[:prompt_tokens] || 0
      output_tokens = usage[:completion_tokens] || 0

      # Ищем модель в БД, если нет - используем дефолты
      ai_model = AiModel.find_by(model_id: response[:model])

      if ai_model
        ai_model.calculate_cost(input_tokens, output_tokens)
      else
        # Fallback на дефолтные цены из AiModel::DEFAULTS
        defaults = AiModel::DEFAULTS[response[:model]]
        if defaults
          input_cost_per_1k = defaults[:input_cost_per_1k] || 0
          output_cost_per_1k = defaults[:output_cost_per_1k] || 0
        else
          input_cost_per_1k = 0
          output_cost_per_1k = 0
        end

        input_cost = (input_tokens.to_f / 1000) * input_cost_per_1k
        output_cost = (output_tokens.to_f / 1000) * output_cost_per_1k

        {
          input_cost: input_cost.round(6),
          output_cost: output_cost.round(6),
          total_cost: (input_cost + output_cost).round(6)
        }
      end
    end
  end

  class LimitExceededError < StandardError; end
  class GenerationError < StandardError; end
end
