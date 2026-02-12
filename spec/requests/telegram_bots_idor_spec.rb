# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TelegramBots IDOR Protection', type: :request do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  let(:project1) { create(:project, user: user1) }
  let(:project2) { create(:project, user: user2) }

  let(:bot1) { create(:telegram_bot, project: project1) }
  let(:bot2) { create(:telegram_bot, project: project2) }

  describe 'GET /projects/:project_id/telegram_bots/:id (show)' do
    context 'when user owns the bot' do
      before { sign_in user1 }

      it 'allows access to own bot' do
        get project_telegram_bot_path(project1, bot1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user tries to access another users bot' do
      before { sign_in user1 }

      it 'prevents access via project scoping' do
        # Пытаемся получить доступ к боту user2 через проект user1
        expect {
          get project_telegram_bot_path(project1, bot2)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'prevents direct access via different project' do
        # Пытаемся получить доступ к проекту user2
        expect {
          get project_telegram_bot_path(project2, bot2)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when not authenticated' do
      it 'redirects to sign in' do
        get project_telegram_bot_path(project1, bot1)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /projects/:project_id/telegram_bots/:id/edit (edit)' do
    context 'when user owns the bot' do
      before { sign_in user1 }

      it 'allows editing own bot' do
        get edit_project_telegram_bot_path(project1, bot1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user tries to edit another users bot' do
      before { sign_in user1 }

      it 'prevents editing via IDOR' do
        expect {
          get edit_project_telegram_bot_path(project1, bot2)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'PATCH /projects/:project_id/telegram_bots/:id (update)' do
    context 'when user owns the bot' do
      before { sign_in user1 }

      it 'allows updating own bot' do
        patch project_telegram_bot_path(project1, bot1),
              params: { telegram_bot: { channel_name: 'New Name' } }

        expect(response).to redirect_to(project_telegram_bot_path(project1, bot1))
        expect(bot1.reload.channel_name).to eq('New Name')
      end
    end

    context 'when user tries to update another users bot' do
      before { sign_in user1 }

      it 'prevents updating via IDOR' do
        original_name = bot2.channel_name

        expect {
          patch project_telegram_bot_path(project1, bot2),
                params: { telegram_bot: { channel_name: 'Hacked Name' } }
        }.to raise_error(ActiveRecord::RecordNotFound)

        expect(bot2.reload.channel_name).to eq(original_name)
      end

      it 'prevents updating via different project' do
        original_name = bot2.channel_name

        expect {
          patch project_telegram_bot_path(project2, bot2),
                params: { telegram_bot: { channel_name: 'Hacked Name' } }
        }.to raise_error(ActiveRecord::RecordNotFound)

        expect(bot2.reload.channel_name).to eq(original_name)
      end
    end
  end

  describe 'DELETE /projects/:project_id/telegram_bots/:id (destroy)' do
    context 'when user owns the bot' do
      before { sign_in user1 }

      it 'allows deleting own bot' do
        bot_to_delete = create(:telegram_bot, project: project1)

        expect {
          delete project_telegram_bot_path(project1, bot_to_delete)
        }.to change(TelegramBot, :count).by(-1)

        expect(response).to redirect_to(project_telegram_bots_path(project1))
      end
    end

    context 'when user tries to delete another users bot' do
      before { sign_in user1 }

      it 'prevents deletion via IDOR' do
        expect {
          delete project_telegram_bot_path(project1, bot2)
        }.to raise_error(ActiveRecord::RecordNotFound)

        expect(TelegramBot.exists?(bot2.id)).to be true
      end

      it 'prevents deletion via different project' do
        expect {
          delete project_telegram_bot_path(project2, bot2)
        }.to raise_error(ActiveRecord::RecordNotFound)

        expect(TelegramBot.exists?(bot2.id)).to be true
      end
    end
  end

  describe 'POST /projects/:project_id/telegram_bots/:id/verify (verify)' do
    context 'when user owns the bot' do
      before do
        sign_in user1
        allow_any_instance_of(Telegram::VerifyService).to receive(:verify!).and_return(true)
      end

      it 'allows verifying own bot' do
        post verify_project_telegram_bot_path(project1, bot1)

        expect(response).to redirect_to(project_telegram_bot_path(project1, bot1))
      end
    end

    context 'when user tries to verify another users bot' do
      before { sign_in user1 }

      it 'prevents verification via IDOR' do
        expect {
          post verify_project_telegram_bot_path(project1, bot2)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'GET /projects/:project_id/telegram_bots/:id/subscriber_analytics' do
    context 'when user owns the bot' do
      before { sign_in user1 }

      it 'allows viewing own bot analytics' do
        get subscriber_analytics_project_telegram_bot_path(project1, bot1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user tries to view another users bot analytics' do
      before { sign_in user1 }

      it 'prevents viewing via IDOR' do
        expect {
          get subscriber_analytics_project_telegram_bot_path(project1, bot2)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'prevents viewing via different project' do
        expect {
          get subscriber_analytics_project_telegram_bot_path(project2, bot2)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'POST /projects/:project_id/telegram_bots (create)' do
    context 'when user owns the project' do
      before { sign_in user1 }

      it 'allows creating bot in own project' do
        expect {
          post project_telegram_bots_path(project1),
               params: {
                 telegram_bot: {
                   bot_token: 'test_token',
                   bot_username: 'test_bot',
                   channel_id: '-1001234567890'
                 }
               }
        }.to change(project1.telegram_bots, :count).by(1)
      end
    end

    context 'when user tries to create bot in another users project' do
      before { sign_in user1 }

      it 'prevents creating bot via IDOR' do
        expect {
          post project_telegram_bots_path(project2),
               params: {
                 telegram_bot: {
                   bot_token: 'test_token',
                   bot_username: 'test_bot',
                   channel_id: '-1001234567890'
                 }
               }
        }.to raise_error(ActiveRecord::RecordNotFound)

        expect(project2.telegram_bots.count).to eq(0)
      end
    end
  end

  describe 'Security edge cases' do
    before { sign_in user1 }

    context 'with manipulated IDs in URL' do
      it 'prevents access via UUID manipulation' do
        # Пытаемся подставить ID бота user2 в URL проекта user1
        fake_url = "/projects/#{project1.id}/telegram_bots/#{bot2.id}"

        expect {
          get fake_url
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'prevents access via sequential ID guessing' do
        # Даже если злоумышленник угадает UUID, scoping защитит
        expect {
          get project_telegram_bot_path(project1, bot2.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with SQL injection attempts' do
      it 'safely handles malicious project_id' do
        malicious_project_id = "#{project1.id}'; DROP TABLE telegram_bots;--"

        expect {
          get "/projects/#{malicious_project_id}/telegram_bots/#{bot1.id}"
        }.to raise_error(ActiveRecord::RecordNotFound)

        # Проверяем, что таблица всё ещё существует
        expect(TelegramBot.count).to be >= 0
      end

      it 'safely handles malicious bot_id' do
        malicious_bot_id = "#{bot1.id}' OR '1'='1"

        expect {
          get project_telegram_bot_path(project1, malicious_bot_id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with authorization bypass attempts' do
      it 'does not leak bot existence information' do
        # Обе попытки должны давать одинаковую ошибку (RecordNotFound),
        # не раскрывая существование ресурса

        # Несуществующий bot
        expect {
          get project_telegram_bot_path(project1, SecureRandom.uuid)
        }.to raise_error(ActiveRecord::RecordNotFound)

        # Существующий bot другого пользователя
        expect {
          get project_telegram_bot_path(project1, bot2.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'Multi-tenancy verification' do
    let(:user3) { create(:user) }
    let(:project3) { create(:project, user: user3) }
    let(:bot3) { create(:telegram_bot, project: project3) }

    before { sign_in user1 }

    it 'isolates resources between multiple users' do
      # User1 может видеть только свои ресурсы
      expect {
        get project_telegram_bot_path(project1, bot1)
      }.not_to raise_error

      # User1 не может видеть ресурсы user2
      expect {
        get project_telegram_bot_path(project2, bot2)
      }.to raise_error(ActiveRecord::RecordNotFound)

      # User1 не может видеть ресурсы user3
      expect {
        get project_telegram_bot_path(project3, bot3)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'prevents cross-project resource access' do
      # User1 не может получить bot1 через проект user2
      expect {
        get project_telegram_bot_path(project2, bot1)
      }.to raise_error(ActiveRecord::RecordNotFound)

      # User1 не может получить bot2 через свой проект
      expect {
        get project_telegram_bot_path(project1, bot2)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'Pundit authorization integration' do
    before { sign_in user1 }

    it 'combines scoping with policy authorization' do
      # Даже если scoping пропустит запрос, Pundit должен его заблокировать
      # Это двойная защита: scoping + authorize

      allow_any_instance_of(TelegramBotsController).to receive(:set_telegram_bot) do
        # Эмулируем обход scoping (для теста)
        @telegram_bot = bot2
      end

      expect {
        get project_telegram_bot_path(project1, bot2)
      }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
