class HealthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    health_status = {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: Rails.application.config.version || '1.0.0',
      environment: Rails.env,
      checks: {}
    }

    # Database check
    begin
      ActiveRecord::Base.connection.execute('SELECT 1')
      health_status[:checks][:database] = { status: 'ok', message: 'Connected' }
    rescue => e
      health_status[:checks][:database] = { status: 'error', message: e.message }
      health_status[:status] = 'error'
    end

    # Redis check
    begin
      Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')).ping
      health_status[:checks][:redis] = { status: 'ok', message: 'Connected' }
    rescue => e
      health_status[:checks][:redis] = { status: 'error', message: e.message }
      health_status[:status] = 'error'
    end

    # Sidekiq check
    begin
      Sidekiq::Stats.new
      health_status[:checks][:sidekiq] = { status: 'ok', message: 'Running' }
    rescue => e
      health_status[:checks][:sidekiq] = { status: 'error', message: e.message }
      health_status[:status] = 'error'
    end

    status_code = health_status[:status] == 'ok' ? :ok : :service_unavailable
    render json: health_status, status: status_code
  end
end
