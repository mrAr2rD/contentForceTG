# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  # Skip authentication for health checks
  if respond_to?(:skip_before_action)
    skip_before_action :authenticate_user!, raise: false
  end

  def index
    checks = {
      database: check_database,
      redis: check_redis,
      timestamp: Time.current.iso8601
    }

    status = checks[:database][:status] == 'ok' ? :ok : :service_unavailable

    render json: {
      status: status == :ok ? 'healthy' : 'unhealthy',
      version: Rails.application.class.module_parent_name,
      environment: Rails.env,
      checks: checks
    }, status: status
  end

  private

  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    { status: 'ok', message: 'Database connected' }
  rescue StandardError => e
    { status: 'error', message: e.message }
  end

  def check_redis
    if defined?(Redis) && ENV['REDIS_URL'].present?
      Redis.new(url: ENV['REDIS_URL']).ping
      { status: 'ok', message: 'Redis connected' }
    else
      { status: 'skipped', message: 'Redis not configured' }
    end
  rescue StandardError => e
    { status: 'error', message: e.message }
  end
end
