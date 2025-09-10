# frozen_string_literal: true

Rails.application.configure do
  if ENV['GOOGLE_MAPS_API_KEY'].blank?
    Rails.logger.warn "Google Maps API key not configured. Maps functionality will be disabled."
  else
    Rails.logger.info "Google Maps API configured successfully"
  end

  config.google_maps = {
    rate_limit: {
      requests_per_second: 50,
      burst_limit: 100
    },
    default_region: 'BR',
    language: 'pt-BR'
  }
end
