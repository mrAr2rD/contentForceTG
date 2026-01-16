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

  AVAILABLE_MODELS = {
    'gpt-4-turbo' => {
      name: 'GPT-4 Turbo',
      provider: 'OpenAI',
      context_length: 128_000,
      cost_per_1k_tokens: { input: 0.01, output: 0.03 },
      recommended_for: ['Качественный контент', 'Сложные задачи']
    },
    'claude-3-opus' => {
      name: 'Claude 3 Opus',
      provider: 'Anthropic',
      context_length: 200_000,
      cost_per_1k_tokens: { input: 0.015, output: 0.075 },
      recommended_for: ['Длинный контент', 'Анализ']
    },
    'claude-3-sonnet' => {
      name: 'Claude 3 Sonnet',
      provider: 'Anthropic',
      context_length: 200_000,
      cost_per_1k_tokens: { input: 0.003, output: 0.015 },
      recommended_for: ['Баланс цена/качество', 'Универсальный']
    },
    'claude-3-haiku' => {
      name: 'Claude 3 Haiku',
      provider: 'Anthropic',
      context_length: 200_000,
      cost_per_1k_tokens: { input: 0.00025, output: 0.00125 },
      recommended_for: ['Быстрые задачи', 'Экономия']
    },
    'gpt-3.5-turbo' => {
      name: 'GPT-3.5 Turbo',
      provider: 'OpenAI',
      context_length: 16_385,
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

  # Type casting для гарантии правильных типов
  def temperature
    super&.to_f || DEFAULT_TEMPERATURE
  end

  def max_tokens
    super&.to_i || DEFAULT_MAX_TOKENS
  end
end
