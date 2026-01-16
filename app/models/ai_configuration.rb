# frozen_string_literal: true

class AiConfiguration < ApplicationRecord
  # Encrypt API key (allow blank values)
  # Temporarily disabled encryption until RAILS_MASTER_KEY is configured
  # encrypts :openrouter_api_key, deterministic: false, ignore_case: true

  # Singleton pattern - только одна конфигурация
  def self.current
    first_or_create!(
      default_model: DEFAULT_MODEL,
      temperature: DEFAULT_TEMPERATURE,
      max_tokens: DEFAULT_MAX_TOKENS
    )
  end

  # Проверка наличия API ключа
  def api_key_configured?
    openrouter_api_key.present? && !openrouter_api_key.empty?
  end

  # Получить API ключ (для использования в клиенте)
  def api_key
    return ENV['OPENROUTER_API_KEY'] if openrouter_api_key.blank?
    openrouter_api_key
  end

  # Используем тот же список моделей, что и в Project
  AVAILABLE_MODELS = {
    # Free tier
    'deepseek/deepseek-chat' => {
      name: 'DeepSeek Chat (Бесплатно)',
      provider: 'DeepSeek',
      tier: :free
    },
    'google/gemini-2.0-flash-exp:free' => {
      name: 'Gemini 2.0 Flash (Бесплатно)',
      provider: 'Google',
      tier: :free
    },
    'meta-llama/llama-3.2-3b-instruct:free' => {
      name: 'Llama 3.2 3B (Бесплатно)',
      provider: 'Meta',
      tier: :free
    },

    # Starter tier
    'openai/gpt-3.5-turbo' => {
      name: 'GPT-3.5 Turbo',
      provider: 'OpenAI',
      tier: :starter
    },
    'anthropic/claude-3-haiku' => {
      name: 'Claude 3 Haiku',
      provider: 'Anthropic',
      tier: :starter
    },
    'google/gemini-pro' => {
      name: 'Gemini Pro',
      provider: 'Google',
      tier: :starter
    },
    'meta-llama/llama-3-8b-instruct' => {
      name: 'Llama 3 8B',
      provider: 'Meta',
      tier: :starter
    },

    # Pro tier
    'anthropic/claude-3.5-sonnet' => {
      name: 'Claude 3.5 Sonnet',
      provider: 'Anthropic',
      tier: :pro
    },
    'openai/gpt-4-turbo' => {
      name: 'GPT-4 Turbo',
      provider: 'OpenAI',
      tier: :pro
    },
    'openai/gpt-4o' => {
      name: 'GPT-4o',
      provider: 'OpenAI',
      tier: :pro
    },
    'google/gemini-pro-1.5' => {
      name: 'Gemini Pro 1.5',
      provider: 'Google',
      tier: :pro
    },
    'meta-llama/llama-3-70b-instruct' => {
      name: 'Llama 3 70B',
      provider: 'Meta',
      tier: :pro
    },

    # Business tier
    'anthropic/claude-3-opus' => {
      name: 'Claude 3 Opus',
      provider: 'Anthropic',
      tier: :business
    },
    'openai/gpt-4-turbo-preview' => {
      name: 'GPT-4 Turbo Preview',
      provider: 'OpenAI',
      tier: :business
    },
    'openai/o1-preview' => {
      name: 'OpenAI o1 Preview',
      provider: 'OpenAI',
      tier: :business
    },
    'google/gemini-ultra' => {
      name: 'Gemini Ultra',
      provider: 'Google',
      tier: :business
    },
    'deepseek/deepseek-coder' => {
      name: 'DeepSeek Coder',
      provider: 'DeepSeek',
      tier: :business
    },
    'anthropic/claude-3-sonnet' => {
      name: 'Claude 3 Sonnet',
      provider: 'Anthropic',
      tier: :pro
    }
  }.freeze

  DEFAULT_MODEL = 'deepseek/deepseek-chat'
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

  # Type casting для гарантии правильных типов
  def temperature
    super&.to_f || DEFAULT_TEMPERATURE
  end

  def max_tokens
    super&.to_i || DEFAULT_MAX_TOKENS
  end
end
