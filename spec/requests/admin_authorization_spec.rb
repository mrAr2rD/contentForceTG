# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Authorization', type: :request do
  let(:admin_user) { create(:user, role: :admin) }
  let(:regular_user) { create(:user, role: :user) }

  describe 'Admin area access control' do
    context 'as admin user' do
      before { sign_in admin_user }

      it 'allows access to admin dashboard' do
        get admin_root_path
        expect(response).to have_http_status(:ok)
      end

      it 'allows access to users index' do
        get admin_users_path
        expect(response).to have_http_status(:ok)
      end

      it 'allows access to projects index' do
        get admin_projects_path
        expect(response).to have_http_status(:ok)
      end

      it 'allows access to payments index' do
        get admin_payments_path
        expect(response).to have_http_status(:ok)
      end

      it 'allows access to AI settings' do
        get edit_admin_ai_settings_path
        expect(response).to have_http_status(:ok)
      end

      it 'allows access to payment settings' do
        get edit_admin_payment_settings_path
        expect(response).to have_http_status(:ok)
      end

      it 'allows destructive actions' do
        user_to_delete = create(:user)

        expect {
          delete admin_user_path(user_to_delete)
        }.to change(User, :count).by(-1)
      end
    end

    context 'as regular user' do
      before { sign_in regular_user }

      it 'denies access to admin dashboard' do
        get admin_root_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Доступ запрещен')
      end

      it 'denies access to users index' do
        get admin_users_path
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to projects index' do
        get admin_projects_path
        expect(response).to redirect_to(root_path)
      end

      it 'denies access to AI settings' do
        get edit_admin_ai_settings_path
        expect(response).to redirect_to(root_path)
      end

      it 'denies destructive actions' do
        user_to_delete = create(:user)

        expect {
          delete admin_user_path(user_to_delete)
        }.not_to change(User, :count)

        expect(response).to redirect_to(root_path)
      end

      it 'logs unauthorized access attempts' do
        expect(Rails.logger).to receive(:warn).with(/Unauthorized admin access attempt/)

        get admin_root_path
      end
    end

    context 'as guest (not signed in)' do
      it 'redirects to sign in page' do
        get admin_root_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'does not allow any admin actions' do
        get admin_users_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'Pundit integration' do
    before { sign_in admin_user }

    it 'includes Pundit::Authorization in Admin controllers' do
      expect(Admin::ApplicationController.ancestors).to include(Pundit::Authorization)
    end

    it 'rescues from Pundit::NotAuthorizedError' do
      # Симулируем Pundit ошибку
      allow_any_instance_of(Admin::DashboardController).to receive(:index).and_raise(Pundit::NotAuthorizedError)

      get admin_root_path

      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to include('нет прав')
    end

    it 'logs Pundit authorization failures' do
      allow_any_instance_of(Admin::DashboardController).to receive(:index).and_raise(Pundit::NotAuthorizedError)

      expect(Rails.logger).to receive(:warn).with(/Pundit authorization failed/)

      get admin_root_path
    end
  end

  describe 'Privilege escalation prevention' do
    before { sign_in regular_user }

    context 'with manipulated session' do
      it 'cannot elevate privileges via session tampering' do
        # Пытаемся подменить данные в сессии (это не должно работать)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(regular_user)

        get admin_root_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Доступ запрещен')
      end
    end

    context 'with direct URL access' do
      it 'blocks access to admin routes via direct URL' do
        # Даже зная URL, regular user не должен получить доступ
        admin_urls = [
          admin_root_path,
          admin_users_path,
          admin_projects_path,
          edit_admin_ai_settings_path,
          edit_admin_payment_settings_path
        ]

        admin_urls.each do |url|
          get url
          expect(response).to redirect_to(root_path)
        end
      end
    end

    context 'with role manipulation in database' do
      it 'immediately reflects role changes' do
        # Admin становится regular user
        admin_user.update!(role: :user)
        sign_in admin_user

        get admin_root_path

        expect(response).to redirect_to(root_path)
      end

      it 'immediately grants access when promoted to admin' do
        # Regular user становится admin
        regular_user.update!(role: :admin)
        sign_in regular_user

        get admin_root_path

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'Sensitive operations' do
    context 'as admin' do
      before { sign_in admin_user }

      it 'allows viewing user details' do
        user = create(:user)
        get admin_user_path(user)

        expect(response).to have_http_status(:ok)
      end

      it 'allows editing users' do
        user = create(:user)
        get edit_admin_user_path(user)

        expect(response).to have_http_status(:ok)
      end

      it 'allows deleting users' do
        user = create(:user)

        expect {
          delete admin_user_path(user)
        }.to change(User, :count).by(-1)
      end

      it 'allows viewing payment information' do
        payment = create(:payment, user: create(:user))
        get admin_payment_path(payment)

        expect(response).to have_http_status(:ok)
      end

      it 'allows refunding payments' do
        payment = create(:payment, user: create(:user), status: :completed)

        post refund_admin_payment_path(payment)

        expect(response).to redirect_to(admin_payment_path(payment))
      end
    end

    context 'as regular user' do
      before { sign_in regular_user }

      it 'denies viewing other users details' do
        user = create(:user)
        get admin_user_path(user)

        expect(response).to redirect_to(root_path)
      end

      it 'denies editing users' do
        user = create(:user)
        get edit_admin_user_path(user)

        expect(response).to redirect_to(root_path)
      end

      it 'denies deleting users' do
        user = create(:user)

        expect {
          delete admin_user_path(user)
        }.not_to change(User, :count)
      end

      it 'denies viewing payment information' do
        payment = create(:payment, user: create(:user))
        get admin_payment_path(payment)

        expect(response).to redirect_to(root_path)
      end

      it 'denies refunding payments' do
        payment = create(:payment, user: create(:user))

        post refund_admin_payment_path(payment)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'IP logging for security audits' do
    before { sign_in regular_user }

    it 'logs IP address on unauthorized admin access' do
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return('192.168.1.100')

      expect(Rails.logger).to receive(:warn).with(/192\.168\.1\.100/)

      get admin_root_path
    end

    it 'logs user ID on unauthorized access' do
      expect(Rails.logger).to receive(:warn).with(/user #{regular_user.id}/)

      get admin_root_path
    end
  end
end
