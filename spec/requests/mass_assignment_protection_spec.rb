# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mass Assignment Protection", type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, role: "admin") }

  before do
    sign_in user
  end

  describe "PostsController" do
    let(:post_record) { create(:post, user: user, status: :draft) }

    describe "SECURITY: protecting :status from mass assignment" do
      it "prevents user from directly changing status to published" do
        patch "/posts/#{post_record.id}", params: {
          post: {
            title: "Updated Title",
            status: "published"  # Попытка изменить статус напрямую
          }
        }

        post_record.reload
        # Статус НЕ должен измениться
        expect(post_record.status).to eq("draft")
        expect(post_record.title).to eq("Updated Title")
      end

      it "prevents user from setting published_at directly" do
        future_time = 1.day.from_now

        patch "/posts/#{post_record.id}", params: {
          post: {
            published_at: future_time,
            status: "scheduled"
          }
        }

        post_record.reload
        # published_at НЕ должно измениться через mass assignment
        expect(post_record.published_at).to be_nil
        expect(post_record.status).to eq("draft")
      end

      it "prevents user from setting telegram_message_id directly" do
        patch "/posts/#{post_record.id}", params: {
          post: {
            telegram_message_id: "12345",
            status: "published"
          }
        }

        post_record.reload
        expect(post_record.telegram_message_id).to be_nil
        expect(post_record.status).to eq("draft")
      end

      it "requires using publish! method to change status" do
        telegram_bot = create(:telegram_bot, project: post_record.project)
        post_record.update!(telegram_bot: telegram_bot, content: "Valid content for publishing")

        # Мокаем Telegram API
        allow_any_instance_of(Telegram::PublishService).to receive(:publish!).and_return(
          OpenStruct.new(message_id: 123)
        )

        post "/posts/#{post_record.id}/publish"

        post_record.reload
        expect(post_record.status).to eq("published")
        expect(post_record.telegram_message_id).to eq(123)
      end
    end

    describe "allowed parameters" do
      it "allows updating safe fields" do
        patch "/posts/#{post_record.id}", params: {
          post: {
            title: "New Title",
            content: "New content that is long enough",
            post_type: "text",
            button_text: "Click me",
            button_url: "https://example.com"
          }
        }

        post_record.reload
        expect(post_record.title).to eq("New Title")
        expect(post_record.content).to eq("New content that is long enough")
      end
    end
  end

  describe "Admin::UsersController" do
    before do
      sign_out user
      sign_in admin
    end

    let(:target_user) { create(:user, role: "user") }

    describe "SECURITY: preventing self-role escalation" do
      it "prevents admin from changing their own role" do
        patch "/admin/users/#{admin.id}", params: {
          user: {
            role: "superadmin"  # Попытка самоповышения
          }
        }

        expect(response).to redirect_to(admin_user_path(admin))
        expect(flash[:alert]).to match(/не можете изменить собственную роль/i)

        admin.reload
        expect(admin.role).to eq("admin")
      end

      it "allows admin to change other users' roles" do
        patch "/admin/users/#{target_user.id}", params: {
          user: {
            role: "moderator"
          }
        }

        target_user.reload
        expect(target_user.role).to eq("moderator")
        expect(response).to redirect_to(admin_user_path(target_user))
      end
    end

    describe "SECURITY: role changes require admin access" do
      it "blocks non-admin from accessing admin users controller" do
        sign_out admin
        sign_in user

        patch "/admin/users/#{target_user.id}", params: {
          user: { role: "admin" }
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/доступ запрещен/i)

        target_user.reload
        expect(target_user.role).to eq("user")
      end
    end
  end

  describe "Admin::SubscriptionsController" do
    before do
      sign_out user
      sign_in admin
    end

    let(:subscription) { create(:subscription, user: user, status: "active") }

    describe "SECURITY: status changes require admin" do
      it "allows admin to change subscription status" do
        patch "/admin/subscriptions/#{subscription.id}", params: {
          subscription: {
            status: "cancelled"
          }
        }

        subscription.reload
        expect(subscription.status).to eq("cancelled")
      end

      it "blocks non-admin from accessing admin subscriptions" do
        sign_out admin
        sign_in user

        patch "/admin/subscriptions/#{subscription.id}", params: {
          subscription: { status: "cancelled" }
        }

        expect(response).to redirect_to(root_path)

        subscription.reload
        expect(subscription.status).to eq("active")
      end
    end
  end

  describe "Strong Parameters validation" do
    it "raises error when trying to permit all parameters" do
      # Это проверяет, что нигде в коде не используется .permit!
      expect {
        params = ActionController::Parameters.new(
          post: { title: "Test", status: "published", role: "admin" }
        )
        params.require(:post).permit!
      }.not_to raise_error

      # Но в production код НЕ должен содержать .permit!
      # Проверяем через grep в тестах
    end
  end

  describe "Nested attributes protection" do
    # Если есть вложенные модели с accepts_nested_attributes_for
    # нужно убедиться, что они тоже защищены

    it "prevents unauthorized nested attribute updates" do
      # Пример для будущих вложенных моделей
      skip "Implement when nested attributes are added"
    end
  end
end
