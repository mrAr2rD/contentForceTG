class Admin::SponsorBannersController < Admin::ApplicationController
  before_action :set_sponsor_banner, only: %i[edit update destroy]

  def index
    @sponsor_banners = SponsorBanner.order(created_at: :desc).page(params[:page]).per(10)
  end

  def new
    @sponsor_banner = SponsorBanner.new
  end

  def create
    @sponsor_banner = SponsorBanner.new(sponsor_banner_params)

    if @sponsor_banner.save
      redirect_to admin_sponsor_banners_path, notice: "Рекламный баннер успешно создан"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @sponsor_banner.update(sponsor_banner_params)
      redirect_to admin_sponsor_banners_path, notice: "Рекламный баннер успешно обновлён"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sponsor_banner.destroy
    redirect_to admin_sponsor_banners_path, notice: "Рекламный баннер удалён"
  end

  private

  def set_sponsor_banner
    @sponsor_banner = SponsorBanner.find(params[:id])
  end

  def sponsor_banner_params
    params.require(:sponsor_banner).permit(:title, :description, :url, :enabled, :display_on, :icon)
  end
end
