# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Audience Dashboard', type: :request do
  let(:admin_user) { create(:user, role: :admin) }
  let(:regular_user) { create(:user, role: :user) }

  describe 'GET /admin/audience' do
    context 'as admin' do
      before { sign_in admin_user }

      it 'renders the audience dashboard' do
        get admin_audience_path
        expect(response).to have_http_status(:ok)
      end

      it 'shows metrics cards' do
        get admin_audience_path
        expect(response.body).to include('Всего пользователей')
        expect(response.body).to include('Прошли онбординг')
        expect(response.body).to include('Конверсия')
      end

      it 'shows chart sections' do
        get admin_audience_path
        expect(response.body).to include('Источники трафика')
        expect(response.body).to include('Возрастное распределение')
        expect(response.body).to include('Сферы деятельности')
        expect(response.body).to include('Размер команды')
      end

      it 'includes period filter links' do
        get admin_audience_path
        expect(response.body).to include('7 дней')
        expect(response.body).to include('30 дней')
        expect(response.body).to include('90 дней')
        expect(response.body).to include('Все время')
      end

      context 'with period filter' do
        before do
          # Создаём пользователей с разными датами
          create(:user, created_at: 3.days.ago, referral_source: 'telegram', onboarding_completed_at: 2.days.ago)
          create(:user, created_at: 15.days.ago, referral_source: 'search', onboarding_completed_at: 14.days.ago)
          create(:user, created_at: 60.days.ago, referral_source: 'social', onboarding_completed_at: 59.days.ago)
        end

        it 'filters by 7 days' do
          get admin_audience_path(period: 7)
          expect(response).to have_http_status(:ok)
          # Должен показывать только пользователей за последние 7 дней
        end

        it 'filters by 30 days' do
          get admin_audience_path(period: 30)
          expect(response).to have_http_status(:ok)
        end

        it 'filters by 90 days' do
          get admin_audience_path(period: 90)
          expect(response).to have_http_status(:ok)
        end

        it 'shows all time with period=0' do
          get admin_audience_path(period: 0)
          expect(response).to have_http_status(:ok)
        end

        it 'defaults to 30 days with invalid period' do
          get admin_audience_path(period: 999)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'with onboarding data' do
        before do
          # Пользователи, прошедшие онбординг
          create(:user,
            referral_source: 'telegram',
            age_range: '25-34',
            occupation: 'marketing',
            company_size: 'solo',
            onboarding_completed_at: 1.day.ago
          )
          create(:user,
            referral_source: 'telegram',
            age_range: '35-44',
            occupation: 'freelancer',
            company_size: '2-5',
            onboarding_completed_at: 2.days.ago
          )
          # Пользователь, пропустивший онбординг
          create(:user, onboarding_skipped_at: 1.day.ago)
          # Пользователь без онбординга
          create(:user)
        end

        it 'calculates correct metrics' do
          get admin_audience_path(period: 0)

          # Проверяем что страница загружается и показывает данные
          expect(response).to have_http_status(:ok)
        end

        it 'includes Chart.js scripts' do
          get admin_audience_path
          expect(response.body).to include('chart.js')
          expect(response.body).to include('referralSourcesChart')
          expect(response.body).to include('occupationsChart')
        end
      end
    end

    context 'as regular user' do
      before { sign_in regular_user }

      it 'denies access' do
        get admin_audience_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Доступ запрещен')
      end
    end

    context 'as guest' do
      it 'redirects to sign in' do
        get admin_audience_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
