# frozen_string_literal: true

class TelegramBotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_telegram_bot, only: [:show, :edit, :update, :destroy, :verify, :subscriber_analytics]
  layout "dashboard"

  def index
    @telegram_bots = @project.telegram_bots.order(created_at: :desc)
  end

  def show
    authorize @telegram_bot
  end

  def new
    @telegram_bot = @project.telegram_bots.build
    authorize @telegram_bot
  end

  def create
    @telegram_bot = @project.telegram_bots.build(telegram_bot_params)
    authorize @telegram_bot

    if @telegram_bot.save
      # Verify bot in background
      VerifyTelegramBotJob.perform_later(@telegram_bot.id) if defined?(VerifyTelegramBotJob)
      redirect_to project_telegram_bot_path(@project, @telegram_bot), 
                  notice: 'Бот добавлен! Проверка подключения...'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @telegram_bot
  end

  def update
    authorize @telegram_bot

    if @telegram_bot.update(telegram_bot_params)
      redirect_to project_telegram_bot_path(@project, @telegram_bot), 
                  notice: 'Бот обновлен!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @telegram_bot
    @telegram_bot.destroy
    redirect_to project_telegram_bots_path(@project), 
                notice: 'Бот удален!', 
                status: :see_other
  end

  def verify
    authorize @telegram_bot

    begin
      Telegram::VerifyService.new(@telegram_bot).verify!
      redirect_to project_telegram_bot_path(@project, @telegram_bot),
                  notice: 'Бот успешно верифицирован!'
    rescue StandardError => e
      redirect_to project_telegram_bot_path(@project, @telegram_bot),
                  alert: "Ошибка верификации: #{e.message}"
    end
  end

  def subscriber_analytics
    authorize @telegram_bot

    @period = params[:period]&.to_i || 30
    @from = @period.days.ago
    @to = Time.current

    @subscriber_events = @telegram_bot.subscriber_events
                                       .by_date_range(@from, @to)
                                       .order(event_at: :desc)

    @stats = SubscriberEvent.where(telegram_bot: @telegram_bot)
                            .stats_for_period(from: @from, to: @to)

    @invite_links = @telegram_bot.invite_links.with_joins.order(join_count: :desc).limit(10)
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_telegram_bot
    @telegram_bot = @project.telegram_bots.find(params[:id])
  end

  def telegram_bot_params
    params.require(:telegram_bot).permit(
      :bot_token, :bot_username, :channel_id, :channel_name
    )
  end
end
