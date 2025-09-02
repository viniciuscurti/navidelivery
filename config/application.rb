require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module NaviDelivery
  class Application < Rails::Application
    config.load_defaults 7.1

    # Multi-tenant configuration
    config.active_record.schema_format = :sql

    # API configuration
    config.api_only_paths = ["/api"]

    # Time zone
    config.time_zone = 'America/Sao_Paulo'

    # CORS atualizado para endpoints públicos de tracking e WebSocket
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '/api/v1/deliveries/track/*', headers: :any, methods: [:get, :options]
      end
      allow do
        origins '*'
        resource '/cable', headers: :any, methods: [:get, :post, :options]
      end
    end

    # Background jobs
    config.active_job.queue_adapter = :sidekiq

    # Generators configuration
    config.generators do |g|
      g.test_framework :rspec
      g.factory_bot true
      g.view_specs false
      g.helper_specs false
      g.routing_specs false
    end
  end
end
