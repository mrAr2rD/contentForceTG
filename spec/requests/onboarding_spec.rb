# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding', type: :request do
  describe 'GET /onboarding' do
    context 'when user needs onboarding' do
      let(:user) { create(:user, created_at: Time.zone.parse('2026-02-14')) }

      before { sign_in user }

      it 'renders onboarding page' do
        get onboarding_path
        expect(response).to have_http_status(:ok)
      end

      it 'shows first step (referral_source)' do
        get onboarding_path
        expect(response.body).to include('Откуда вы узнали о нас')
      end
    end

    context 'when user already completed onboarding' do
      let(:user) do
        create(:user,
          created_at: Time.zone.parse('2026-02-14'),
          onboarding_completed_at: 1.day.ago
        )
      end

      before { sign_in user }

      it 'redirects to dashboard' do
        get onboarding_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user skipped onboarding' do
      let(:user) do
        create(:user,
          created_at: Time.zone.parse('2026-02-14'),
          onboarding_skipped_at: 1.day.ago
        )
      end

      before { sign_in user }

      it 'redirects to dashboard' do
        get onboarding_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when not signed in' do
      it 'redirects to sign in' do
        get onboarding_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /onboarding/update_step' do
    let(:user) { create(:user, created_at: Time.zone.parse('2026-02-14')) }

    before { sign_in user }

    it 'saves step data to session' do
      post update_step_onboarding_path, params: { step: 'referral_source', value: 'telegram' }

      # Следующий GET должен показать второй шаг
      get onboarding_path
      expect(response.body).to include('Сколько вам лет')
    end

    it 'completes onboarding after last step' do
      # Заполняем session заранее
      post update_step_onboarding_path, params: { step: 'referral_source', value: 'telegram' }
      post update_step_onboarding_path, params: { step: 'age_range', value: '25-34' }
      post update_step_onboarding_path, params: { step: 'occupation', value: 'marketing' }
      post update_step_onboarding_path, params: { step: 'company_size', value: 'solo' }

      user.reload
      expect(user.onboarding_completed_at).to be_present
      expect(user.referral_source).to eq('telegram')
      expect(user.age_range).to eq('25-34')
      expect(user.occupation).to eq('marketing')
      expect(user.company_size).to eq('solo')
    end

    it 'redirects to dashboard after completion' do
      # Симулируем полное прохождение
      post update_step_onboarding_path, params: { step: 'referral_source', value: 'search' }
      post update_step_onboarding_path, params: { step: 'age_range', value: '35-44' }
      post update_step_onboarding_path, params: { step: 'occupation', value: 'freelancer' }
      post update_step_onboarding_path, params: { step: 'company_size', value: '2-5' }

      expect(response).to redirect_to(dashboard_path)
    end

    it 'returns bad request for invalid step' do
      post update_step_onboarding_path, params: { step: 'invalid_step', value: 'test' }
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns bad request for missing value' do
      post update_step_onboarding_path, params: { step: 'referral_source', value: '' }
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'POST /onboarding/skip' do
    let(:user) { create(:user, created_at: Time.zone.parse('2026-02-14')) }

    before { sign_in user }

    it 'marks onboarding as skipped' do
      post skip_onboarding_path

      user.reload
      expect(user.onboarding_skipped_at).to be_present
    end

    it 'redirects to dashboard' do
      post skip_onboarding_path
      expect(response).to redirect_to(dashboard_path)
    end

    it 'does not save any onboarding data' do
      # Сначала заполним пару шагов
      post update_step_onboarding_path, params: { step: 'referral_source', value: 'telegram' }

      # Затем пропустим
      post skip_onboarding_path

      user.reload
      expect(user.referral_source).to be_nil
    end
  end

  describe 'Automatic redirect to onboarding' do
    let(:user) { create(:user, created_at: Time.zone.parse('2026-02-14')) }

    before { sign_in user }

    it 'redirects from dashboard to onboarding for new users' do
      get dashboard_path
      expect(response).to redirect_to(onboarding_path)
    end

    it 'does not redirect from API endpoints' do
      get api_v1_projects_path, headers: { 'Accept' => 'application/json' }
      # API должен работать, хотя возможно с 401/403 по другим причинам
      expect(response).not_to redirect_to(onboarding_path)
    end

    it 'does not redirect from pages controller' do
      get terms_path
      expect(response).not_to redirect_to(onboarding_path)
    end
  end

  describe 'After sign in redirect' do
    let(:user) { create(:user, created_at: Time.zone.parse('2026-02-14')) }

    it 'redirects to onboarding for new users after sign in' do
      post user_session_path, params: {
        user: { email: user.email, password: 'password123' }
      }

      expect(response).to redirect_to(onboarding_path)
    end

    it 'redirects to dashboard for users who completed onboarding' do
      user.update!(onboarding_completed_at: 1.day.ago)

      post user_session_path, params: {
        user: { email: user.email, password: 'password123' }
      }

      expect(response).to redirect_to(dashboard_path)
    end
  end
end
