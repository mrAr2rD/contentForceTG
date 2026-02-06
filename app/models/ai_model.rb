# frozen_string_literal: true

# Модель AI с ценами OpenRouter
# Хранит стоимость токенов для расчёта расходов
class AiModel < ApplicationRecord
  # Валидации
  validates :model_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :input_cost_per_1k, numericality: { greater_than_or_equal_to: 0 }
  validates :output_cost_per_1k, numericality: { greater_than_or_equal_to: 0 }
  validates :tier, inclusion: { in: %w[free starter pro business] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_tier, ->(tier) { where(tier: tier) }
  scope :free_tier, -> { by_tier('free') }
  scope :by_provider, ->(provider) { where(provider: provider) }

  # Стандартные модели с ценами OpenRouter ($/1K tokens)
  DEFAULTS = {
    # Free tier
    'deepseek/deepseek-chat' => {
      name: 'DeepSeek Chat (Бесплатно)',
      provider: 'DeepSeek',
      tier: 'free',
      input_cost_per_1k: 0,
      output_cost_per_1k: 0
    },
    'google/gemini-2.0-flash-exp:free' => {
      name: 'Gemini 2.0 Flash (Бесплатно)',
      provider: 'Google',
      tier: 'free',
      input_cost_per_1k: 0,
      output_cost_per_1k: 0
    },
    'meta-llama/llama-3.2-3b-instruct:free' => {
      name: 'Llama 3.2 3B (Бесплатно)',
      provider: 'Meta',
      tier: 'free',
      input_cost_per_1k: 0,
      output_cost_per_1k: 0
    },

    # Starter tier
    'openai/gpt-3.5-turbo' => {
      name: 'GPT-3.5 Turbo',
      provider: 'OpenAI',
      tier: 'starter',
      input_cost_per_1k: 0.0005,
      output_cost_per_1k: 0.0015
    },
    'anthropic/claude-3-haiku' => {
      name: 'Claude 3 Haiku',
      provider: 'Anthropic',
      tier: 'starter',
      input_cost_per_1k: 0.00025,
      output_cost_per_1k: 0.00125
    },
    'google/gemini-pro' => {
      name: 'Gemini Pro',
      provider: 'Google',
      tier: 'starter',
      input_cost_per_1k: 0.000125,
      output_cost_per_1k: 0.000375
    },
    'meta-llama/llama-3-8b-instruct' => {
      name: 'Llama 3 8B',
      provider: 'Meta',
      tier: 'starter',
      input_cost_per_1k: 0.0001,
      output_cost_per_1k: 0.0001
    },

    # Pro tier
    'anthropic/claude-3.5-sonnet' => {
      name: 'Claude 3.5 Sonnet',
      provider: 'Anthropic',
      tier: 'pro',
      input_cost_per_1k: 0.003,
      output_cost_per_1k: 0.015
    },
    'openai/gpt-4-turbo' => {
      name: 'GPT-4 Turbo',
      provider: 'OpenAI',
      tier: 'pro',
      input_cost_per_1k: 0.01,
      output_cost_per_1k: 0.03
    },
    'openai/gpt-4o' => {
      name: 'GPT-4o',
      provider: 'OpenAI',
      tier: 'pro',
      input_cost_per_1k: 0.005,
      output_cost_per_1k: 0.015
    },
    'google/gemini-pro-1.5' => {
      name: 'Gemini Pro 1.5',
      provider: 'Google',
      tier: 'pro',
      input_cost_per_1k: 0.00125,
      output_cost_per_1k: 0.005
    },
    'meta-llama/llama-3-70b-instruct' => {
      name: 'Llama 3 70B',
      provider: 'Meta',
      tier: 'pro',
      input_cost_per_1k: 0.0008,
      output_cost_per_1k: 0.0008
    },
    'anthropic/claude-3-sonnet' => {
      name: 'Claude 3 Sonnet',
      provider: 'Anthropic',
      tier: 'pro',
      input_cost_per_1k: 0.003,
      output_cost_per_1k: 0.015
    },

    # Business tier
    'anthropic/claude-3-opus' => {
      name: 'Claude 3 Opus',
      provider: 'Anthropic',
      tier: 'business',
      input_cost_per_1k: 0.015,
      output_cost_per_1k: 0.075
    },
    'openai/gpt-4-turbo-preview' => {
      name: 'GPT-4 Turbo Preview',
      provider: 'OpenAI',
      tier: 'business',
      input_cost_per_1k: 0.01,
      output_cost_per_1k: 0.03
    },
    'openai/o1-preview' => {
      name: 'OpenAI o1 Preview',
      provider: 'OpenAI',
      tier: 'business',
      input_cost_per_1k: 0.015,
      output_cost_per_1k: 0.06
    },
    'google/gemini-ultra' => {
      name: 'Gemini Ultra',
      provider: 'Google',
      tier: 'business',
      input_cost_per_1k: 0.0025,
      output_cost_per_1k: 0.0075
    },
    'deepseek/deepseek-coder' => {
      name: 'DeepSeek Coder',
      provider: 'DeepSeek',
      tier: 'business',
      input_cost_per_1k: 0,
      output_cost_per_1k: 0
    }
  }.freeze

  # Рассчитать стоимость запроса
  def calculate_cost(input_tokens, output_tokens)
    input_cost = (input_tokens.to_f / 1000) * input_cost_per_1k.to_f
    output_cost = (output_tokens.to_f / 1000) * output_cost_per_1k.to_f
    {
      input_cost: input_cost.round(6),
      output_cost: output_cost.round(6),
      total_cost: (input_cost + output_cost).round(6)
    }
  end

  # Бесплатная ли модель
  def free?
    tier == 'free' || (input_cost_per_1k.to_f.zero? && output_cost_per_1k.to_f.zero?)
  end

  # Класс-метод для проверки бесплатности модели
  def self.free_model?(model_id)
    model = find_by(model_id: model_id)
    return AiConfiguration.free_model?(model_id) unless model # Fallback на старый метод
    model.free?
  end

  # Получить модель или создать из дефолтов
  def self.find_or_initialize_from_defaults(model_id)
    find_by(model_id: model_id) || new(DEFAULTS[model_id]&.merge(model_id: model_id))
  end
end
