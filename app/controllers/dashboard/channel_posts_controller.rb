# frozen_string_literal: true

module Dashboard
  class ChannelPostsController < BaseController
    before_action :check_feature_enabled
    before_action :set_channel_site
    before_action :set_channel_post, only: [ :show, :edit, :update ]

    # GET /dashboard/channel_sites/:channel_site_id/channel_posts
    def index
      @channel_posts = @channel_site.channel_posts.recent.page(params[:page]).per(50)
    end

    # PATCH /dashboard/channel_sites/:channel_site_id/channel_posts/bulk_update
    def bulk_update
      ids = params[:ids] || []
      action_type = params[:action_type]

      @channel_posts = @channel_site.channel_posts.where(id: ids)

      case action_type
      when "show"
        @channel_posts.update_all(visibility: "visible")
      when "hide"
        @channel_posts.update_all(visibility: "hidden")
      when "feature"
        @channel_posts.update_all(featured: true)
      when "unfeature"
        @channel_posts.update_all(featured: false)
      end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "channel-posts-table",
            partial: "channel_posts_table",
            locals: { channel_posts: @channel_site.channel_posts.recent.page(params[:page]).per(50) }
          )
        end
        format.html { redirect_to dashboard_channel_site_channel_posts_path(@channel_site), notice: "Посты обновлены" }
      end
    end

    # GET /dashboard/channel_sites/:channel_site_id/channel_posts/:id
    def show
    end

    # GET /dashboard/channel_sites/:channel_site_id/channel_posts/:id/edit
    def edit
    end

    # PATCH/PUT /dashboard/channel_sites/:channel_site_id/channel_posts/:id
    def update
      if @channel_post.update(channel_post_params)
        redirect_to dashboard_channel_site_channel_post_path(@channel_site, @channel_post),
                    notice: "Пост успешно обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def check_feature_enabled
      unless SiteConfiguration.channel_sites_enabled?
        redirect_to dashboard_path, alert: "Функция мини-сайтов временно недоступна"
      end
    end

    def set_channel_site
      @channel_site = ChannelSite.find(params[:channel_site_id])
      authorize_channel_site!
    end

    def set_channel_post
      @channel_post = @channel_site.channel_posts.find_by(slug: params[:id]) ||
                      @channel_site.channel_posts.find(params[:id])
    end

    def authorize_channel_site!
      unless current_user.projects.exists?(id: @channel_site.project_id)
        redirect_to dashboard_channel_sites_path, alert: "Доступ запрещён"
      end
    end

    def channel_post_params
      params.require(:channel_post).permit(
        :title, :slug, :content, :excerpt, :visibility, :featured
      )
    end
  end
end
