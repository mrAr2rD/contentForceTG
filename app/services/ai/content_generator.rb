# frozen_string_literal: true

module Ai
  class ContentGenerator
    def initialize(project: nil, user: nil)
      @project = project
      @user = user
      @config = AiConfiguration.current
      @client = OpenRouter::Client.new
    end

    def generate(prompt:, context: {})
      # Проверка лимитов тарифа
      unless can_generate?
        raise LimitExceededError, 'AI generation limit exceeded for current plan'
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

      {
        content: response[:content],
        model_used: response[:model],
        tokens_used: response[:usage][:total_tokens],
        success: true
      }
    rescue OpenRouter::Error => e
      handle_api_error(e, prompt, context)
    rescue StandardError => e
      {
        content: nil,
        error: e.message,
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
        temperature: temperature,
        max_tokens: max_tokens,
        transforms: ['middle-out'],
        route: 'fallback'
      )

      response
    end

    def build_system_prompt(context)
      base_prompt = @config.custom_system_prompt || default_system_prompt

      if @project
        base_prompt += "\n\nПроект: #{@project.name}"
        base_prompt += "\nТон голоса: #{@project.default_tone_of_voice}" if @project.default_tone_of_voice
        base_prompt += "\nОписание: #{@project.description}" if @project.description.present?
      end

      if context[:previous_posts]
        base_prompt += "\n\nПримеры предыдущих постов:\n"
        context[:previous_posts].each do |post|
          base_prompt += "- #{post.content[0..200]}\n"
        end
      end

      if context[:tone_of_voice]
        base_prompt += "\n\nТон голоса: #{context[:tone_of_voice]}"
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

      AiUsageLog.create!(
        user: @user,
        project: @project,
        model_used: response[:model],
        tokens_used: response[:usage][:total_tokens],
        cost: calculate_cost(response),
        purpose: :content_generation
      )

      if @user.subscription
        @user.subscription.increment_usage!(:ai_generations_per_month)
      end
    end

    def can_generate?
      return true unless @user&.subscription

      @user.subscription.can_use?(:ai_generations_per_month)
    end

    def calculate_cost(response)
      model_info = AiConfiguration::AVAILABLE_MODELS[response[:model]]
      return 0 unless model_info

      input_tokens = response[:usage][:prompt_tokens]
      output_tokens = response[:usage][:completion_tokens]

      input_cost = (input_tokens / 1000.0) * model_info[:cost_per_1k_tokens][:input]
      output_cost = (output_tokens / 1000.0) * model_info[:cost_per_1k_tokens][:output]

      input_cost + output_cost
    end
  end

  class LimitExceededError < StandardError; end
  class GenerationError < StandardError; end
end
