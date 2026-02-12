# frozen_string_literal: true

module Admin
  class ArticlesController < Admin::ApplicationController
    before_action :set_article, only: [ :show, :edit, :update, :destroy, :preview ]

    def index
      @articles = Article.includes(:author)
                         .order(created_at: :desc)
                         .page(params[:page]).per(25)

      @articles = @articles.where(status: params[:status]) if params[:status].present?
      @articles = @articles.by_category(params[:category]) if params[:category].present?
    end

    def show
    end

    def new
      @article = Article.new
    end

    def create
      @article = Article.new(article_params)
      @article.author = current_user

      if @article.save
        redirect_to admin_article_path(@article), notice: "Статья успешно создана"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @article.update(article_params)
        redirect_to admin_article_path(@article), notice: "Статья успешно обновлена"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @article.destroy
      redirect_to admin_articles_path, notice: "Статья удалена", status: :see_other
    end

    def preview
      render layout: false
    end

    def generate_content
      topic = params[:topic]
      style = params[:style] || "informative"

      prompt = build_article_prompt(topic, style)
      generator = Ai::ContentGenerator.new(user: current_user)
      result = generator.generate(prompt: prompt, context: { max_tokens: 4000 })

      if result[:success]
        render json: { success: true, content: result[:content] }
      else
        render json: { success: false, error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def set_article
      # Поддержка поиска как по UUID, так и по slug (из-за to_param)
      @article = Article.find_by(id: params[:id]) || Article.find_by!(slug: params[:id])
    end

    def article_params
      params.require(:article).permit(
        :title, :slug, :content, :excerpt, :meta_title, :meta_description,
        :status, :published_at, :category, :cover_image, tags: []
      )
    end

    def build_article_prompt(topic, style)
      style_instructions = case style
      when "casual"
                             "Пиши в дружелюбном, разговорном тоне. Используй простые слова и короткие предложения."
      when "technical"
                             "Пиши в техническом стиле с деталями и примерами кода. Будь точен и структурирован."
      when "promotional"
                             "Пиши в маркетинговом стиле, подчёркивая преимущества. Используй призывы к действию."
      else # informative
                             "Пиши в информативном стиле, структурированно и понятно."
      end

      <<~PROMPT
        Напиши статью для блога о продукте ContentForce на тему: "#{topic}"

        ContentForce — это SaaS-платформа для автоматизации создания и публикации контента в Telegram с использованием AI.

        Основные функции продукта:
        - Генерация контента с AI (Claude, GPT-4, Gemini)
        - Планирование и отложенная публикация в Telegram
        - Управление несколькими каналами и проектами
        - Аналитика публикаций и аудитории
        - Генерация изображений для постов

        #{style_instructions}

        Структура статьи:
        1. Заголовок (H1)
        2. Введение (1-2 абзаца)
        3. Основная часть с подзаголовками (H2)
        4. Практические советы или примеры
        5. Заключение с призывом к действию

        Используй Markdown для форматирования.
        Длина: 800-1500 слов.
      PROMPT
    end
  end
end
