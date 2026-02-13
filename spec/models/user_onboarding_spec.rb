# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, 'Onboarding', type: :model do
  describe 'onboarding constants' do
    it 'has REFERRAL_SOURCES defined' do
      expect(User::REFERRAL_SOURCES).to be_a(Hash)
      expect(User::REFERRAL_SOURCES).to include('search', 'social', 'telegram')
    end

    it 'has AGE_RANGES defined' do
      expect(User::AGE_RANGES).to be_a(Hash)
      expect(User::AGE_RANGES).to include('18-24', '25-34', '35-44')
    end

    it 'has OCCUPATIONS defined' do
      expect(User::OCCUPATIONS).to be_a(Hash)
      expect(User::OCCUPATIONS).to include('marketing', 'blogger', 'freelancer')
    end

    it 'has COMPANY_SIZES defined' do
      expect(User::COMPANY_SIZES).to be_a(Hash)
      expect(User::COMPANY_SIZES).to include('solo', '2-5', '100+')
    end
  end

  describe '#onboarding_required?' do
    context 'for new users (after feature launch)' do
      let(:user) { create(:user, created_at: Time.zone.parse('2026-02-14')) }

      it 'returns true when onboarding not completed' do
        expect(user.onboarding_required?).to be true
      end

      it 'returns false when onboarding completed' do
        user.update!(onboarding_completed_at: Time.current)
        expect(user.onboarding_required?).to be false
      end

      it 'returns false when onboarding skipped' do
        user.update!(onboarding_skipped_at: Time.current)
        expect(user.onboarding_required?).to be false
      end
    end

    context 'for old users (before feature launch)' do
      let(:user) { create(:user, created_at: Time.zone.parse('2026-02-01')) }

      it 'returns false even without completing onboarding' do
        expect(user.onboarding_required?).to be false
      end
    end
  end

  describe '#complete_onboarding!' do
    let(:user) { create(:user, created_at: Time.zone.parse('2026-02-14')) }
    let(:onboarding_data) do
      {
        referral_source: 'telegram',
        age_range: '25-34',
        occupation: 'marketing',
        company_size: '2-5'
      }
    end

    it 'saves all onboarding data' do
      user.complete_onboarding!(onboarding_data)

      user.reload
      expect(user.referral_source).to eq('telegram')
      expect(user.age_range).to eq('25-34')
      expect(user.occupation).to eq('marketing')
      expect(user.company_size).to eq('2-5')
    end

    it 'sets onboarding_completed_at timestamp' do
      freeze_time do
        user.complete_onboarding!(onboarding_data)
        expect(user.onboarding_completed_at).to eq(Time.current)
      end
    end

    it 'marks onboarding as no longer required' do
      user.complete_onboarding!(onboarding_data)
      expect(user.onboarding_required?).to be false
    end
  end

  describe '#skip_onboarding!' do
    let(:user) { create(:user, created_at: Time.zone.parse('2026-02-14')) }

    it 'sets onboarding_skipped_at timestamp' do
      freeze_time do
        user.skip_onboarding!
        expect(user.onboarding_skipped_at).to eq(Time.current)
      end
    end

    it 'marks onboarding as no longer required' do
      user.skip_onboarding!
      expect(user.onboarding_required?).to be false
    end

    it 'does not save any onboarding data' do
      user.skip_onboarding!

      expect(user.referral_source).to be_nil
      expect(user.age_range).to be_nil
      expect(user.occupation).to be_nil
      expect(user.company_size).to be_nil
    end
  end

  describe 'human-readable name methods' do
    let(:user) do
      create(:user,
        referral_source: 'telegram',
        age_range: '25-34',
        occupation: 'marketing',
        company_size: 'solo'
      )
    end

    it '#referral_source_name returns translated value' do
      expect(user.referral_source_name).to eq('Telegram')
    end

    it '#age_range_name returns translated value' do
      expect(user.age_range_name).to eq('25-34 года')
    end

    it '#occupation_name returns translated value' do
      expect(user.occupation_name).to eq('Маркетинг / SMM')
    end

    it '#company_size_name returns translated value' do
      expect(user.company_size_name).to eq('Только я')
    end

    it 'returns original value if translation not found' do
      user.update!(referral_source: 'unknown_source')
      expect(user.referral_source_name).to eq('unknown_source')
    end
  end

  describe 'scopes' do
    let!(:completed_user) do
      create(:user,
        referral_source: 'search',
        onboarding_completed_at: 1.day.ago
      )
    end

    let!(:skipped_user) do
      create(:user, onboarding_skipped_at: 1.day.ago)
    end

    let!(:pending_user) { create(:user) }

    describe '.completed_onboarding' do
      it 'returns users who completed onboarding' do
        expect(User.completed_onboarding).to include(completed_user)
        expect(User.completed_onboarding).not_to include(skipped_user, pending_user)
      end
    end

    describe '.skipped_onboarding' do
      it 'returns users who skipped onboarding' do
        expect(User.skipped_onboarding).to include(skipped_user)
        expect(User.skipped_onboarding).not_to include(completed_user, pending_user)
      end
    end

    describe '.onboarding_pending' do
      it 'returns users with pending onboarding' do
        expect(User.onboarding_pending).to include(pending_user)
        expect(User.onboarding_pending).not_to include(completed_user, skipped_user)
      end
    end

    describe '.with_onboarding_data' do
      it 'returns users who completed or skipped onboarding' do
        expect(User.with_onboarding_data).to include(completed_user, skipped_user)
        expect(User.with_onboarding_data).not_to include(pending_user)
      end
    end
  end
end
