require 'rails_helper'

RSpec.describe SponsorBanner, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:url) }
    it { should validate_length_of(:title).is_at_most(100) }
    it { should validate_length_of(:description).is_at_most(200) }
  end

  describe "associations" do
    it "has one attached icon" do
      expect(SponsorBanner.new.icon).to be_an_instance_of(ActiveStorage::Attached::One)
    end
  end

  describe "scopes" do
    let!(:enabled_public_banner) { create(:sponsor_banner, :enabled, :for_public) }
    let!(:enabled_dashboard_banner) { create(:sponsor_banner, :enabled, :for_dashboard) }
    let!(:disabled_banner) { create(:sponsor_banner, enabled: false) }

    describe ".enabled" do
      it "returns only enabled banners" do
        expect(SponsorBanner.enabled).to include(enabled_public_banner)
        expect(SponsorBanner.enabled).to include(enabled_dashboard_banner)
        expect(SponsorBanner.enabled).not_to include(disabled_banner)
      end
    end

    describe ".for_public" do
      it "returns only public_pages banners" do
        expect(SponsorBanner.for_public).to include(enabled_public_banner)
        expect(SponsorBanner.for_public).not_to include(enabled_dashboard_banner)
      end
    end

    describe ".for_dashboard" do
      it "returns only dashboard banners" do
        expect(SponsorBanner.for_dashboard).to include(enabled_dashboard_banner)
        expect(SponsorBanner.for_dashboard).not_to include(enabled_public_banner)
      end
    end
  end

  describe ".current" do
    it "returns the active public banner" do
      banner = create(:sponsor_banner, :enabled, :for_public)
      expect(SponsorBanner.current(:public_pages)).to eq(banner)
    end

    it "returns the active dashboard banner" do
      banner = create(:sponsor_banner, :enabled, :for_dashboard)
      expect(SponsorBanner.current(:dashboard)).to eq(banner)
    end

    it "defaults to public_pages when no argument" do
      banner = create(:sponsor_banner, :enabled, :for_public)
      expect(SponsorBanner.current).to eq(banner)
    end
  end

  describe "singleton pattern" do
    it "disables other banners of same display_on when enabling a new one" do
      banner1 = create(:sponsor_banner, :enabled, :for_public)
      banner2 = create(:sponsor_banner, enabled: false, display_on: :public_pages)

      banner2.update(enabled: true)

      expect(banner1.reload.enabled).to be false
      expect(banner2.reload.enabled).to be true
    end

    it "keeps only one banner enabled per display_on location" do
      create(:sponsor_banner, :enabled, :for_public)
      create(:sponsor_banner, :enabled, :for_public)
      create(:sponsor_banner, :enabled, :for_public)

      expect(SponsorBanner.enabled.for_public.count).to eq(1)
    end

    it "allows different banners for different display_on locations" do
      public_banner = create(:sponsor_banner, :enabled, :for_public)
      dashboard_banner = create(:sponsor_banner, :enabled, :for_dashboard)

      expect(public_banner.reload.enabled).to be true
      expect(dashboard_banner.reload.enabled).to be true
      expect(SponsorBanner.enabled.count).to eq(2)
    end
  end

  describe "URL validation" do
    it "accepts valid URLs" do
      banner = build(:sponsor_banner, url: "https://example.com")
      expect(banner).to be_valid
    end

    it "rejects invalid URLs" do
      banner = build(:sponsor_banner, url: "not-a-url")
      expect(banner).not_to be_valid
    end
  end
end
