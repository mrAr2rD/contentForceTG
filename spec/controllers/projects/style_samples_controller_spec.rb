# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::StyleSamplesController, type: :controller do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }

  before do
    sign_in user
  end

  describe "#normalize_telegram_username" do
    it "normalizes various Telegram username formats" do
      controller.params = { project_id: project.id }

      # Прямой доступ к private методу для тестирования
      normalize = ->(input) { controller.send(:normalize_telegram_username, input) }

      # Полные URL
      expect(normalize.call("t.me/newcosmos_school")).to eq("newcosmos_school")
      expect(normalize.call("https://t.me/newcosmos_school")).to eq("newcosmos_school")
      expect(normalize.call("http://t.me/newcosmos_school")).to eq("newcosmos_school")

      # С @ префиксом
      expect(normalize.call("@newcosmos_school")).to eq("newcosmos_school")

      # Уже нормализованный
      expect(normalize.call("newcosmos_school")).to eq("newcosmos_school")

      # С trailing slash
      expect(normalize.call("t.me/newcosmos_school/")).to eq("newcosmos_school")
      expect(normalize.call("https://t.me/newcosmos_school/")).to eq("newcosmos_school")

      # С дополнительными путями (берём только первый сегмент)
      expect(normalize.call("t.me/newcosmos_school/123")).to eq("newcosmos_school")
      expect(normalize.call("https://t.me/newcosmos_school/posts/456")).to eq("newcosmos_school")

      # Пустые значения
      expect(normalize.call("")).to eq("")
      expect(normalize.call(nil)).to eq("")
      expect(normalize.call("   ")).to eq("")

      # С пробелами
      expect(normalize.call("  t.me/newcosmos_school  ")).to eq("newcosmos_school")
    end
  end

  describe "POST #import_from_telegram" do
    let(:telegram_session) { create(:telegram_session, user: user, status: :authorized) }

    before do
      allow(ImportStyleSamplesJob).to receive(:perform_later)
    end

    it "normalizes channel username before passing to job" do
      post :import_from_telegram, params: {
        project_id: project.id,
        telegram_session_id: telegram_session.id,
        channel_username: "t.me/newcosmos_school",
        limit: 100
      }

      expect(ImportStyleSamplesJob).to have_received(:perform_later).with(
        hash_including(
          channel_username: "newcosmos_school" # Нормализованное значение
        )
      )
    end

    it "handles various username formats" do
      formats = [
        "t.me/testchannel",
        "https://t.me/testchannel",
        "@testchannel",
        "testchannel"
      ]

      formats.each do |format|
        post :import_from_telegram, params: {
          project_id: project.id,
          telegram_session_id: telegram_session.id,
          channel_username: format,
          limit: 100
        }

        expect(ImportStyleSamplesJob).to have_received(:perform_later).with(
          hash_including(channel_username: "testchannel")
        )
      end
    end

    it "clamps limit to valid range" do
      # Слишком маленький
      post :import_from_telegram, params: {
        project_id: project.id,
        telegram_session_id: telegram_session.id,
        channel_username: "testchannel",
        limit: 5
      }

      expect(ImportStyleSamplesJob).to have_received(:perform_later).with(
        hash_including(limit: 10) # Минимум 10
      )

      # Слишком большой
      post :import_from_telegram, params: {
        project_id: project.id,
        telegram_session_id: telegram_session.id,
        channel_username: "testchannel",
        limit: 2000
      }

      expect(ImportStyleSamplesJob).to have_received(:perform_later).with(
        hash_including(limit: 1000) # Максимум 1000
      )
    end
  end
end
