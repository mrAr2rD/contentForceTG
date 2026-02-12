# frozen_string_literal: true

module Admin
  class TelegramBotsController < Admin::ApplicationController
    def index
      @telegram_bots = TelegramBot.includes(:project)
                                  .order(created_at: :desc)
                                  .page(params[:page]).per(25)
    end

    def show
      @telegram_bot = TelegramBot.find(params[:id])
    end

    def destroy
      @telegram_bot = TelegramBot.find(params[:id])
      @telegram_bot.destroy
      redirect_to admin_telegram_bots_path, notice: "Telegram бот удален", status: :see_other
    end
  end
end
