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
    let!(:enabled_banner) { create(:sponsor_banner, :enabled) }
    let!(:disabled_banner) { create(:sponsor_banner, enabled: false) }

    describe ".enabled" do
      it "returns only enabled banners" do
        expect(SponsorBanner.enabled).to include(enabled_banner)
        expect(SponsorBanner.enabled).not_to include(disabled_banner)
      end
    end

    describe ".active" do
      it "returns the most recent enabled banner" do
        expect(SponsorBanner.active).to eq(enabled_banner)
      end
    end
  end

  describe ".current" do
    it "returns the active banner" do
      banner = create(:sponsor_banner, :enabled)
      expect(SponsorBanner.current).to eq(banner)
    end
  end

  describe "singleton pattern" do
    it "disables other banners when enabling a new one" do
      banner1 = create(:sponsor_banner, :enabled)
      banner2 = create(:sponsor_banner, enabled: false)

      banner2.update(enabled: true)

      expect(banner1.reload.enabled).to be false
      expect(banner2.reload.enabled).to be true
    end

    it "keeps only one banner enabled" do
      create(:sponsor_banner, :enabled)
      create(:sponsor_banner, :enabled)
      create(:sponsor_banner, :enabled)

      expect(SponsorBanner.enabled.count).to eq(1)
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
