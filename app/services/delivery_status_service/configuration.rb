# Configuration for DeliveryStatusService
module DeliveryStatusService
  class Configuration
    attr_accessor :enable_async_jobs, :retry_attempts, :timeout_seconds, :enable_notifications

    def initialize
      @enable_async_jobs = true
      @retry_attempts = 3
      @timeout_seconds = 30
      @enable_notifications = true
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end

# Exemplo de configuração em config/initializers/delivery_status_service.rb
# DeliveryStatusService.configure do |config|
#   config.enable_async_jobs = Rails.env.production?
#   config.retry_attempts = 5
#   config.timeout_seconds = 60
#   config.enable_notifications = true
# end
