# frozen_string_literal: true

module Dashboard
  class ChannelSitesController < BaseController
    before_action :check_feature_enabled
    before_action :set_channel_site, only: [ :show, :edit, :update, :destroy, :enable, :disable, :sync, :verify_domain ]
    before_action :set_telegram_bots, only: [ :new, :create, :edit, :update ]

    # GET /dashboard/channel_sites
    def index
      @channel_sites = current_user.projects.includes(:channel_sites).flat_map(&:channel_sites)
    end

    # GET /dashboard/channel_sites/:id
    def show
      @recent_posts = @channel_site.channel_posts.recent.limit(10)
      @stats = {
        total_posts: @channel_site.channel_posts.count,
        published_posts: @channel_site.channel_posts.published.count,
        total_views: @channel_site.channel_posts.sum(:site_views_count),
        featured_posts: @channel_site.channel_posts.featured.count
      }
    end

    # GET /dashboard/channel_sites/new
    def new
      @channel_site = ChannelSite.new
    end

    # POST /dashboard/channel_sites
    def create
      @channel_site = ChannelSite.new(channel_site_params)

      if @channel_site.save
        # Автоматически включаем мини-сайт если бот верифицирован
        if @channel_site.telegram_bot.can_create_channel_site?
          @channel_site.enable!
          redirect_to dashboard_channel_site_path(@channel_site),
                      notice: "Мини-сайт создан и автоматически включён"
        else
          redirect_to dashboard_channel_site_path(@channel_site),
                      notice: "Мини-сайт создан. Верифицируйте бота для активации."
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /dashboard/channel_sites/:id/edit
    def edit
    end

    # PATCH/PUT /dashboard/channel_sites/:id
    def update
      if @channel_site.update(channel_site_params)
        redirect_to dashboard_channel_site_path(@channel_site), notice: "Мини-сайт успешно обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /dashboard/channel_sites/:id
    def destroy
      @channel_site.destroy
      redirect_to dashboard_channel_sites_path, notice: "Мини-сайт удалён"
    end

    # POST /dashboard/channel_sites/:id/enable
    def enable
      unless @channel_site.telegram_bot.can_create_channel_site?
        redirect_to dashboard_channel_site_path(@channel_site),
                    alert: "Бот должен быть верифицирован и являться администратором канала"
        return
      end

      @channel_site.enable!
      redirect_to dashboard_channel_site_path(@channel_site), notice: "Мини-сайт включён"
    end

    # POST /dashboard/channel_sites/:id/disable
    def disable
      @channel_site.disable!
      redirect_to dashboard_channel_site_path(@channel_site), notice: "Мини-сайт выключен"
    end

    # POST /dashboard/channel_sites/:id/sync
    def sync
      unless @channel_site.telegram_bot.can_create_channel_site?
        redirect_to dashboard_channel_site_path(@channel_site),
                    alert: "Бот должен быть верифицирован и являться администратором канала"
        return
      end

      # Проверяем есть ли Telegram сессия для полной синхронизации
      has_telegram_session = @channel_site.project.user.telegram_sessions&.active&.exists?

      if has_telegram_session
        # Запускаем в фоне, т.к. синхронизация с Pyrogram может занять время
        ChannelSites::SyncJob.perform_later(@channel_site.id)
        redirect_to dashboard_channel_site_path(@channel_site),
                    notice: "Синхронизация истории канала запущена в фоне"
      else
        # Быстрое обновление — новые посты приходят через webhook
        @channel_site.update(last_synced_at: Time.current)
        redirect_to dashboard_channel_site_path(@channel_site),
                    notice: "Новые посты добавляются автоматически через webhook. Для импорта истории канала требуется авторизация Telegram."
      end
    end

    # POST /dashboard/channel_sites/:id/verify_domain
    def verify_domain
      result = ChannelSites::VerifyDomainService.new(@channel_site).call

      if result[:success]
        redirect_to dashboard_channel_site_path(@channel_site), notice: "Домен успешно подтверждён"
      else
        redirect_to dashboard_channel_site_path(@channel_site), alert: result[:error]
      end
    end

    private

    def check_feature_enabled
      unless SiteConfiguration.channel_sites_enabled?
        redirect_to dashboard_path, alert: "Функция мини-сайтов временно недоступна"
      end
    end

    def set_channel_site
      @channel_site = ChannelSite.find(params[:id])
      authorize_channel_site!
    end

    def set_telegram_bots
      # Только верифицированные боты, которые являются администраторами каналов
      @telegram_bots = current_user.projects
                                   .includes(:telegram_bots)
                                   .flat_map(&:telegram_bots)
                                   .select(&:can_create_channel_site?)
    end

    def authorize_channel_site!
      unless current_user.projects.exists?(id: @channel_site.project_id)
        redirect_to dashboard_channel_sites_path, alert: "Доступ запрещён"
      end
    end

    def channel_site_params
      params.require(:channel_site).permit(
        :telegram_bot_id, :project_id, :subdomain, :custom_domain,
        :site_title, :site_description, :theme,
        :meta_title, :meta_description, :enabled
      )
    end
  end
end
