# frozen_string_literal: true

class ChannelSitesController < ApplicationController
  layout "channel_site"

  skip_before_action :verify_authenticity_token, only: [ :sitemap ]
  before_action :set_channel_site
  before_action :set_channel_post, only: [ :post ]

  # GET / - Главная страница мини-сайта
  def show
    @featured_posts = @channel_site.channel_posts.published.featured.recent.limit(3)
    @recent_posts = @channel_site.channel_posts.published.recent.limit(10)
  end

  # GET /posts - Список всех постов
  def posts
    @posts = @channel_site.channel_posts.published.recent.limit(50)
  end

  # GET /post/:slug - Отдельный пост
  def post
    @channel_post.increment_views!

    # Следующий и предыдущий посты для навигации
    @next_post = @channel_site.channel_posts.published
                              .where("telegram_date > ?", @channel_post.telegram_date)
                              .order(telegram_date: :asc).first
    @prev_post = @channel_site.channel_posts.published
                              .where("telegram_date < ?", @channel_post.telegram_date)
                              .order(telegram_date: :desc).first
  end

  # GET /sitemap.xml - Sitemap для SEO
  def sitemap
    @posts = @channel_site.channel_posts.published.recent

    respond_to do |format|
      format.xml { render layout: false }
    end
  end

  private

  def set_channel_site
    @channel_site = find_channel_site
    render_not_found unless @channel_site&.enabled?
  end

  def find_channel_site
    # Сначала проверяем кастомный домен
    site = ChannelSite.enabled.find_by(custom_domain: request.host)
    return site if site

    # Потом subdomain
    subdomain = extract_subdomain(request.host)
    ChannelSite.enabled.find_by(subdomain: subdomain) if subdomain
  end

  def extract_subdomain(host)
    return nil if host.blank?

    parts = host.split(".")
    return parts.first if parts.length >= 2 && host.include?("localhost")
    return parts.first if parts.length >= 3

    nil
  end

  def set_channel_post
    @channel_post = @channel_site.channel_posts.published.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    # Пробуем найти по id если slug не найден
    @channel_post = @channel_site.channel_posts.published.find(params[:slug])
  end

  def render_not_found
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end
end
