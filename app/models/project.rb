class Project < ApplicationRecord
  # Constants
  AI_MODELS = {
    'anthropic/claude-3.5-sonnet' => 'Claude 3.5 Sonnet',
    'anthropic/claude-3-opus' => 'Claude 3 Opus',
    'openai/gpt-4-turbo' => 'GPT-4 Turbo',
    'openai/gpt-3.5-turbo' => 'GPT-3.5 Turbo',
    'google/gemini-pro' => 'Gemini Pro'
  }.freeze

  WRITING_STYLES = {
    'professional' => 'Профессиональный',
    'casual' => 'Свободный',
    'friendly' => 'Дружелюбный',
    'formal' => 'Деловой',
    'creative' => 'Креативный'
  }.freeze

  # Associations
  belongs_to :user
  has_many :posts, dependent: :destroy
  has_many :telegram_bots, dependent: :destroy

  # Enums
  enum :status, { draft: 0, active: 1, archived: 2 }, default: :draft

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :ai_temperature, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2 }, allow_nil: true
  validates :ai_model, inclusion: { in: %w[
    anthropic/claude-3.5-sonnet
    anthropic/claude-3-opus
    openai/gpt-4-turbo
    openai/gpt-3.5-turbo
    google/gemini-pro
  ] }, allow_nil: true
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
      'professional' => 'Ты профессиональный копирайтер. Пиши в деловом стиле, структурированно и информативно.',
      'casual' => 'Ты креативный автор. Пиши в свободном стиле, используй простой язык и будь естественным.',
      'friendly' => 'Ты дружелюбный автор. Пиши тепло, доступно и располагающе к себе.',
      'formal' => 'Ты официальный представитель. Пиши формально, точно и соблюдая все правила делового этикета.',
      'creative' => 'Ты креативный писатель. Используй яркие образы, метафоры и необычные подходы.'
    }

    style_prompts[writing_style] || style_prompts['professional']
  end
end
