# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminPolicy, type: :policy do
  subject { described_class }

  let(:admin_user) { create(:user, role: :admin) }
  let(:regular_user) { create(:user, role: :user) }
  let(:record) { double('record') }

  permissions :index?, :show?, :create?, :new?, :update?, :edit?, :destroy? do
    context 'for admin user' do
      it 'grants access' do
        expect(subject).to permit(admin_user, record)
      end
    end

    context 'for regular user' do
      it 'denies access' do
        expect { subject.new(regular_user, record) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'for guest (nil user)' do
      it 'denies access' do
        expect { subject.new(nil, record) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe AdminPolicy::Scope do
    let(:scope) { User.all }

    context 'for admin user' do
      it 'resolves all records' do
        resolved_scope = described_class::Scope.new(admin_user, scope).resolve
        expect(resolved_scope).to eq(scope.all)
      end
    end

    context 'for regular user' do
      it 'raises error' do
        expect {
          described_class::Scope.new(regular_user, scope)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'for guest user' do
      it 'raises error' do
        expect {
          described_class::Scope.new(nil, scope)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe 'Edge cases' do
    context 'when user role is changed after policy initialization' do
      it 'still enforces original permissions' do
        policy = subject.new(admin_user, record)

        # Меняем роль пользователя
        admin_user.update!(role: :user)

        # Policy всё ещё разрешает (потому что проверка была при инициализации)
        expect(policy.index?).to be true
      end
    end

    context 'with different record types' do
      it 'works with User records' do
        user_record = create(:user)
        expect { subject.new(admin_user, user_record) }.not_to raise_error
      end

      it 'works with Project records' do
        project_record = create(:project, user: admin_user)
        expect { subject.new(admin_user, project_record) }.not_to raise_error
      end

      it 'works with nil record' do
        expect { subject.new(admin_user, nil) }.not_to raise_error
      end
    end
  end
end
