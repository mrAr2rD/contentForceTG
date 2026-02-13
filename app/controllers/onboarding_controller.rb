# frozen_string_literal: true

# Контроллер для 4-шагового онбординга новых пользователей
class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_onboarding_completed

  layout "onboarding"

  STEPS = %w[referral_source age_range occupation company_size].freeze

  def show
    @step = current_step
    @step_index = STEPS.index(@step)
    @total_steps = STEPS.size
    @onboarding_data = session[:onboarding_data] || {}
  end

  def update_step
    step = params[:step]
    value = params[:value]

    return head :bad_request unless STEPS.include?(step) && value.present?

    # Сохраняем ответ в сессию
    session[:onboarding_data] ||= {}
    session[:onboarding_data][step] = value

    # Определяем следующий шаг
    current_index = STEPS.index(step)
    next_index = current_index + 1

    if next_index >= STEPS.size
      # Последний шаг — сохраняем данные и завершаем
      complete_onboarding
    else
      # Переход на следующий шаг
      respond_to do |format|
        format.turbo_stream do
          @step = STEPS[next_index]
          @step_index = next_index
          @total_steps = STEPS.size
          @onboarding_data = session[:onboarding_data]

          render turbo_stream: [
            turbo_stream.replace(
              "onboarding_progress",
              partial: "onboarding/progress_bar",
              locals: { step_index: @step_index, total_steps: @total_steps }
            ),
            turbo_stream.replace(
              "onboarding_content",
              partial: "onboarding/step_#{@step}",
              locals: {
                step: @step,
                step_index: @step_index,
                total_steps: @total_steps,
                onboarding_data: @onboarding_data
              }
            )
          ]
        end
        format.html { redirect_to onboarding_path }
      end
    end
  end

  def skip
    current_user.skip_onboarding!
    session.delete(:onboarding_data)

    respond_to do |format|
      format.turbo_stream { redirect_to dashboard_path, notice: "Добро пожаловать в ContentForce!" }
      format.html { redirect_to dashboard_path, notice: "Добро пожаловать в ContentForce!" }
    end
  end

  private

  def current_step
    # Возвращаем первый незаполненный шаг или первый шаг
    data = session[:onboarding_data] || {}
    STEPS.find { |s| data[s].blank? } || STEPS.first
  end

  def complete_onboarding
    data = session[:onboarding_data].symbolize_keys
    current_user.complete_onboarding!(data)
    session.delete(:onboarding_data)

    respond_to do |format|
      format.turbo_stream { redirect_to dashboard_path, notice: "Спасибо! Добро пожаловать в ContentForce!" }
      format.html { redirect_to dashboard_path, notice: "Спасибо! Добро пожаловать в ContentForce!" }
    end
  end

  def redirect_if_onboarding_completed
    return if current_user.onboarding_required?

    redirect_to dashboard_path
  end
end
