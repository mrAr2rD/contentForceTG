# frozen_string_literal: true

module Admin
  class InviteLinksController < Admin::ApplicationController
    def index
      @invite_links = InviteLink.includes(telegram_bot: :project)
                                .order(created_at: :desc)
                                .page(params[:page]).per(25)

      @stats = {
        total: InviteLink.count,
        active: InviteLink.active.count,
        revoked: InviteLink.revoked.count,
        total_joins: InviteLink.sum(:join_count)
      }
    end

    def show
      @invite_link = InviteLink.find(params[:id])
    end

    def destroy
      @invite_link = InviteLink.find(params[:id])
      @invite_link.destroy

      redirect_to admin_invite_links_path, notice: "Пригласительная ссылка удалена"
    end
  end
end
