# frozen_string_literal: true

class InviteLinksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_telegram_bot
  before_action :set_invite_link, only: [ :destroy ]
  layout "dashboard"

  def index
    @invite_links = @telegram_bot.invite_links.order(created_at: :desc)
  end

  def new
    @invite_link = @telegram_bot.invite_links.build
  end

  def create
    service = Telegram::InviteLinkService.new(@telegram_bot)

    @invite_link = service.create_invite_link(
      name: params[:invite_link][:name],
      source: params[:invite_link][:source],
      member_limit: params[:invite_link][:member_limit].presence&.to_i,
      expire_date: params[:invite_link][:expire_date].presence&.to_datetime,
      creates_join_request: params[:invite_link][:creates_join_request] == "1"
    )

    redirect_to project_telegram_bot_invite_links_path(@project, @telegram_bot),
                notice: "Пригласительная ссылка создана"
  rescue StandardError => e
    @invite_link = @telegram_bot.invite_links.build(invite_link_params)
    flash.now[:alert] = "Ошибка создания ссылки: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def destroy
    service = Telegram::InviteLinkService.new(@telegram_bot)
    service.revoke_invite_link(@invite_link)

    redirect_to project_telegram_bot_invite_links_path(@project, @telegram_bot),
                notice: "Ссылка отозвана"
  rescue StandardError => e
    redirect_to project_telegram_bot_invite_links_path(@project, @telegram_bot),
                alert: "Ошибка: #{e.message}"
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_telegram_bot
    @telegram_bot = @project.telegram_bots.find(params[:telegram_bot_id])
  end

  def set_invite_link
    @invite_link = @telegram_bot.invite_links.find(params[:id])
  end

  def invite_link_params
    params.require(:invite_link).permit(:name, :source, :member_limit, :expire_date, :creates_join_request)
  end
end
