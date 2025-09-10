# Configuração do Sidekiq
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }

  # Configure the number of threads
  config.concurrency = ENV.fetch('SIDEKIQ_CONCURRENCY', 5).to_i

  # Configure dead job retention
  config.death_handlers << ->(job, ex) do
    Rails.logger.error "Sidekiq job died: #{job['class']} with #{ex.message}"
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
end

# Configure queues
Sidekiq::Cron::Job.load_from_hash({
  'location_ping_cleanup' => {
    'cron' => '0 2 * * *', # Daily at 2 AM
    'class' => 'LocationPingCleanupJob'
  }
}) if defined?(Sidekiq::Cron)
