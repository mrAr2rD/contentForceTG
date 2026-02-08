# frozen_string_literal: true

module Ai
  class StyleAnalyzer
    # Модель для анализа стиля (Claude хорошо справляется с анализом текста)
    ANALYSIS_MODEL = "anthropic/claude-3.5-sonnet"
    MAX_SAMPLES_FOR_ANALYSIS = 20
    MAX_CHARS_PER_SAMPLE = 2000

    def initialize(project)
      @project = project
      @client = Openrouter::Client.new
    end

    def analyze!
      @project.update!(style_analysis_status: :style_analyzing)

      begin
        samples_text = collect_samples_text
        documents_text = collect_documents_text

        if samples_text.blank? && documents_text.blank?
          @project.update!(style_analysis_status: :style_failed)
          return { success: false, error: "Нет данных для анализа" }
        end

        style_prompt = generate_style_prompt(samples_text, documents_text)

        @project.update!(
          custom_style_prompt: style_prompt,
          custom_style_enabled: true,
          style_analysis_status: :style_completed,
          style_analyzed_at: Time.current
        )

        { success: true, style_prompt: style_prompt }
      rescue StandardError => e
        Rails.logger.error "Style analysis failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        @project.update!(style_analysis_status: :style_failed)
        { success: false, error: e.message }
      end
    end

    private

    def collect_samples_text
      samples = @project.style_samples.for_analysis.order(created_at: :desc).limit(MAX_SAMPLES_FOR_ANALYSIS)
      return "" if samples.empty?

      samples.map { |s| s.content.truncate(MAX_CHARS_PER_SAMPLE) }.join("\n\n---\n\n")
    end

    def collect_documents_text
      documents = @project.style_documents.for_analysis.order(created_at: :desc).limit(5)
      return "" if documents.empty?

      documents.map { |d| d.content.truncate(5000) }.join("\n\n---\n\n")
    end

    def generate_style_prompt(samples_text, documents_text)
      analysis_prompt = build_analysis_prompt(samples_text, documents_text)

      response = @client.chat(
        model: ANALYSIS_MODEL,
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: analysis_prompt }
        ],
        temperature: 0.3,
        max_tokens: 2000
      )

      response[:content]
    end

    def system_prompt
      <<~PROMPT
        Ты — эксперт по анализу стиля письма и копирайтингу.
        Твоя задача — проанализировать тексты пользователя и создать детальную инструкцию для AI,
        которая позволит генерировать новые тексты в том же уникальном стиле.

        Инструкция должна быть:
        - Конкретной и практичной (не общие фразы, а точные указания)
        - Структурированной по категориям
        - На русском языке
        - Готовой к использованию как часть system prompt для AI

        Формат ответа — готовая инструкция по стилю без преамбул.
      PROMPT
    end

    def build_analysis_prompt(samples_text, documents_text)
      prompt = <<~PROMPT
        Проанализируй следующие тексты и создай детальную инструкцию по стилю написания.

      PROMPT

      if samples_text.present?
        prompt += <<~SAMPLES
          === ПРИМЕРЫ ПОСТОВ В TELEGRAM ===
          #{samples_text}

        SAMPLES
      end

      if documents_text.present?
        prompt += <<~DOCS
          === ДОКУМЕНТЫ СО СТИЛЕМ ===
          #{documents_text}

        DOCS
      end

      prompt += <<~INSTRUCTIONS
        === ЗАДАНИЕ ===
        На основе этих текстов создай инструкцию по стилю, которая включает:

        1. **Общий тон и настроение**
           - Формальность/неформальность
           - Эмоциональность
           - Отношение к читателю

        2. **Лексика и словарный запас**
           - Характерные слова и выражения
           - Терминология
           - Сленг или профессионализмы

        3. **Синтаксис и структура**
           - Типичная длина предложений
           - Использование списков, заголовков
           - Особенности пунктуации

        4. **Форматирование**
           - Использование эмодзи (часто/редко/никогда, какие)
           - Абзацы и разбивка текста
           - Markdown-форматирование

        5. **Риторические приёмы**
           - Вопросы к читателю
           - Призывы к действию
           - Метафоры и сравнения

        6. **Уникальные особенности**
           - Любые характерные черты, которые выделяют этот стиль

        Напиши инструкцию так, чтобы AI мог её использовать для генерации текстов в этом стиле.
      INSTRUCTIONS

      prompt
    end
  end
end
