# frozen_string_literal: true

class ArticlesController < ApplicationController
  def index
    @articles = Article.published.recent
    @articles = @articles.by_category(params[:category]) if params[:category].present?
    @articles = @articles.page(params[:page]).per(12)
    @featured_articles = Article.featured.limit(3)
    @categories = Article::CATEGORIES
  end

  def show
    @article = Article.published.find_by!(slug: params[:slug])
    @article.increment_views!
    @related_articles = Article.published
                               .where(category: @article.category)
                               .where.not(id: @article.id)
                               .recent
                               .limit(3)
  end
end
