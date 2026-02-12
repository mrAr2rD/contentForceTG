class Project < ApplicationRecord
  # Constants
  AI_MODELS = {
    # Free tier (доступно всем)
    "deepseek/deepseek-chat" => "DeepSeek Chat (Бесплатно)",
    "google/gemini-2.0-flash-exp:free" => "Gemini 2.0 Flash (Бесплатно)",
    "meta-llama/llama-3.2-3b-instruct:free" => "Llama 3.2 3B (Бесплатно)",

    # Budget tier (Starter план)
    "openai/gpt-3.5-turbo" => "GPT-3.5 Turbo",
    "anthropic/claude-3-haiku" => "Claude 3 Haiku",
    "google/gemini-pro" => "Gemini Pro",
    "meta-llama/llama-3-8b-instruct" => "Llama 3 8B",

    # Pro tier (Pro план)
    "anthropic/claude-3.5-sonnet" => "Claude 3.5 Sonnet",
    "openai/gpt-4-turbo" => "GPT-4 Turbo",
    "openai/gpt-4o" => "GPT-4o",
    "google/gemini-pro-1.5" => "Gemini Pro 1.5",
    "meta-llama/llama-3-70b-instruct" => "Llama 3 70B",

    # Premium tier (Business план)
    "anthropic/claude-3-opus" => "Claude 3 Opus",
    "openai/gpt-4-turbo-preview" => "GPT-4 Turbo Preview",
    "openai/o1-preview" => "OpenAI o1 Preview",
    "google/gemini-ultra" => "Gemini Ultra",
    "deepseek/deepseek-coder" => "DeepSeek Coder"
  }.freeze

  # Model tiers for subscription limits
  FREE_MODELS = [
    "deepseek/deepseek-chat",
    "google/gemini-2.0-flash-exp:free",
    "meta-llama/llama-3.2-3b-instruct:free"
  ].freeze

  STARTER_MODELS = FREE_MODELS + [
    "openai/gpt-3.5-turbo",
    "anthropic/claude-3-haiku",
    "google/gemini-pro",
    "meta-llama/llama-3-8b-instruct"
  ].freeze

  PRO_MODELS = STARTER_MODELS + [
    "anthropic/claude-3.5-sonnet",
    "openai/gpt-4-turbo",
    "openai/gpt-4o",
    "google/gemini-pro-1.5",
    "meta-llama/llama-3-70b-instruct"
  ].freeze

  BUSINESS_MODELS = AI_MODELS.keys.freeze

  WRITING_STYLES = {
    "professional" => "Профессиональный",
    "casual" => "Свободный",
    "friendly" => "Дружелюбный",
    "formal" => "Деловой",
    "creative" => "Креативный"
  }.freeze

  # Associations
  belongs_to :user
  has_many :posts, dependent: :destroy
  has_many :telegram_bots, dependent: :destroy
  has_many :channel_sites, dependent: :destroy
  has_many :style_samples, dependent: :destroy
  has_many :style_documents, dependent: :destroy

  # Enums
  enum :status, { draft: 0, active: 1, archived: 2 }, default: :draft
  enum :style_analysis_status, {
    style_pending: 0,
    style_analyzing: 1,
    style_completed: 2,
    style_failed: 3
  }, prefix: :style

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :ai_temperature, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2 }, allow_nil: true
  validates :ai_model, inclusion: { in: AI_MODELS.keys }, allow_nil: true
  validates :writing_style, inclusion: { in: %w[professional casual friendly formal creative] }, allow_nil: true

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :archived, -> { where(status: :archived) }
  scope :recent, -> { order(updated_at: :desc) }

  # Instance methods
  def archive!
    update!(status: :archived)
  end

  def activate!
    update!(status: :active)
  end

  def archived?
    status == "archived"
  end

  def active?
    status == "active"
  end

  def draft?
    status == "draft"
  end

  # AI Configuration methods
  def ai_model_name
    AI_MODELS[ai_model] || ai_model
  end

  def writing_style_name
    WRITING_STYLES[writing_style] || writing_style
  end

  def ai_system_prompt
    return system_prompt if system_prompt.present?

    # Default system prompt based on writing style
    style_prompts = {
      "professional" => "Ты профессиональный копирайтер. Пиши в деловом стиле, структурированно и информативно.",
      "casual" => "Ты креативный автор. Пиши в свободном стиле, используй простой язык и будь естественным.",
      "friendly" => "Ты дружелюбный автор. Пиши тепло, доступно и располагающе к себе.",
      "formal" => "Ты официальный представитель. Пиши формально, точно и соблюдая все правила делового этикета.",
      "creative" => "Ты креативный писатель. Используй яркие образы, метафоры и необычные подходы."
    }

    style_prompts[writing_style] || style_prompts["professional"]
  end

  # Get available models for user's subscription plan
  def available_models(user_plan = :free)
    case user_plan.to_sym
    when :free
      FREE_MODELS
    when :starter
      STARTER_MODELS
    when :pro
      PRO_MODELS
    when :business
      BUSINESS_MODELS
    else
      FREE_MODELS
    end
  end

  # Check if model is available for user
  def model_available_for_user?(model, user)
    plan = user.subscription&.plan&.to_sym || :free
    available_models(plan).include?(model)
  end

  # Get default model for plan
  def self.default_model_for_plan(plan = :free)
    case plan.to_sym
    when :free
      "deepseek/deepseek-chat"
    when :starter
      "anthropic/claude-3-haiku"
    when :pro
      "anthropic/claude-3.5-sonnet"
    when :business
      "anthropic/claude-3-opus"
    else
      "deepseek/deepseek-chat"
    end
  end

  # Style methods
  def has_style_data?
    style_samples.for_analysis.exists? || style_documents.for_analysis.exists?
  end

  def style_samples_count
    style_samples.for_analysis.count
  end

  def style_documents_count
    style_documents.for_analysis.count
  end

  def total_style_words
    samples_words = style_samples.for_analysis.sum { |s| s.word_count }
    docs_words = style_documents.for_analysis.sum { |d| d.word_count }
    samples_words + docs_words
  end

  def can_analyze_style?
    has_style_data? && !style_style_analyzing?
  end

  def reset_style!
    update!(
      custom_style_enabled: false,
      custom_style_prompt: nil,
      style_analysis_status: :style_pending,
      style_analyzed_at: nil
    )
  end
end
