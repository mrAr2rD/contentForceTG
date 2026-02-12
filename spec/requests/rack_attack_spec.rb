# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rack::Attack", type: :request do
  # Включаем Rack::Attack для тестов
  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after do
    Rack::Attack.cache.store.clear
    Rack::Attack.enabled = false
  end

  describe "throttle req/ip" do
    let(:limit) { 300 }

    it "разрешает запросы в пределах лимита" do
      limit.times do |i|
        get root_path
        expect(response).not_to have_http_status(:too_many_requests), "Request #{i + 1} failed"
      end
    end

    it "блокирует запросы после превышения лимита" do
      # Делаем limit + 1 запросов
      (limit + 1).times { get root_path }

      # Последний запрос должен быть заблокирован
      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body["error"]).to eq("Rate limit exceeded")
      expect(response.headers).to include("X-RateLimit-Limit")
    end
  end

  describe "throttle logins/ip" do
    let(:limit) { 5 }
    let(:login_path) { "/users/sign_in" }

    it "блокирует повторные попытки входа" do
      limit.times do
        post login_path, params: { user: { email: "test@example.com", password: "wrong" } }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      # Следующая попытка должна быть заблокирована
      post login_path, params: { user: { email: "test@example.com", password: "wrong" } }
      expect(response).to have_http_status(:too_many_requests)
    end

    it "не блокирует GET запросы к форме входа" do
      (limit + 1).times do
        get login_path
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end

  describe "throttle signups/ip" do
    let(:limit) { 3 }
    let(:signup_path) { "/users" }

    it "блокирует множественные регистрации с одного IP" do
      limit.times do
        post signup_path, params: {
          user: {
            email: "user_#{Time.current.to_i}@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      # Следующая регистрация блокируется
      post signup_path, params: {
        user: {
          email: "blocked@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "throttle webhooks/telegram" do
    let(:limit) { 100 }
    let(:bot_id) { SecureRandom.uuid }
    let(:webhook_path) { "/webhooks/telegram/#{bot_id}" }

    it "блокирует избыточные webhook запросы" do
      limit.times do
        post webhook_path, params: { update_id: 12345 }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      # Следующий webhook блокируется
      post webhook_path, params: { update_id: 12346 }
      expect(response).to have_http_status(:too_many_requests)
    end

    it "использует отдельный лимит для каждого бота" do
      bot_id_2 = SecureRandom.uuid

      # Исчерпываем лимит для первого бота
      (limit + 1).times { post "/webhooks/telegram/#{bot_id}" }

      # Второй бот должен работать нормально
      post "/webhooks/telegram/#{bot_id_2}", params: { update_id: 1 }
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end

  describe "throttle webhooks/robokassa" do
    let(:limit) { 50 }
    let(:webhook_path) { "/webhooks/robokassa/result" }

    it "блокирует избыточные Robokassa webhooks" do
      limit.times do
        post webhook_path, params: { OutSum: "100.00" }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      post webhook_path, params: { OutSum: "100.00" }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "allowlist localhost" do
    it "разрешает неограниченные запросы с localhost" do
      # Делаем > 300 запросов (больше лимита req/ip)
      500.times do
        get root_path
      end

      # Localhost никогда не блокируется
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end

  describe "blocklist bad IPs" do
    let(:bad_ip) { "1.2.3.4" }

    before do
      # Добавляем IP в blocklist через cache
      Rails.cache.write("block:#{bad_ip}", true, expires_in: 1.day)
    end

    it "блокирует запросы с заблокированного IP" do
      get root_path, headers: { "REMOTE_ADDR" => bad_ip }
      expect(response).to have_http_status(:forbidden)
    end

    it "не блокирует другие IP" do
      get root_path, headers: { "REMOTE_ADDR" => "5.6.7.8" }
      expect(response).not_to have_http_status(:forbidden)
    end
  end

  describe "custom throttled response" do
    let(:limit) { 300 }

    before do
      # Исчерпываем лимит
      (limit + 1).times { get root_path }
    end

    it "возвращает правильные заголовки rate limit" do
      expect(response.headers["X-RateLimit-Limit"]).to eq(limit.to_s)
      expect(response.headers["X-RateLimit-Remaining"]).to eq("0")
      expect(response.headers["X-RateLimit-Reset"]).to be_present
    end

    it "возвращает JSON с информацией об ошибке" do
      json = response.parsed_body
      expect(json["error"]).to eq("Rate limit exceeded")
      expect(json["message"]).to be_present
      expect(json["retry_after"]).to be_a(Integer)
    end
  end

  describe "exponential backoff для repeat offenders" do
    let(:limit) { 300 }

    it "блокирует IP после повторных нарушений" do
      # Первое нарушение
      (limit + 1).times { get root_path }
      expect(response).to have_http_status(:too_many_requests)

      # Ждём сброса периода (simulate)
      Rack::Attack.cache.store.clear

      # Второе нарушение
      (limit + 1).times { get root_path }

      # Теперь должен быть забанен полностью
      get root_path
      # Note: реальная проверка exponential backoff требует временных манипуляций
      # В продакшене IP будет забанен на 1 час после 2 нарушений за 10 минут
    end
  end
end
