# frozen_string_literal: true

module Admin
  class PageSeosController < Admin::ApplicationController
    before_action :set_page_seo, only: %i[edit update]

    def index
      @page_seos = PageSeo.ordered
      # Создаём записи для недостающих страниц
      seed_missing_pages
    end

    def edit
    end

    def update
      if @page_seo.update(page_seo_params)
        redirect_to admin_page_seos_path, notice: "SEO настройки для \"#{@page_seo.page_name}\" обновлены!"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_page_seo
      @page_seo = PageSeo.find(params[:id])
    end

    def page_seo_params
      params.require(:page_seo).permit(:title, :description, :og_title, :og_description, :canonical_url, :noindex)
    end

    def seed_missing_pages
      PageSeo::PAGES.keys.each do |slug|
        next if PageSeo.exists?(slug: slug)

        PageSeo.create!(
          slug: slug,
          title: PageSeo::PAGES[slug],
          description: ""
        )
      end
    end
  end
end
